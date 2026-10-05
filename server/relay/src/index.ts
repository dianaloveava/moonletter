/**
 * 月信中转同步服务（Cloudflare Worker + R2）。
 * 只保存密文，接口见仓库 README「同步」一节：
 *   GET    /v1/o/{ns}/{path...}        读对象
 *   PUT    /v1/o/{ns}/{path...}        写对象（已存在返回 409）
 *   DELETE /v1/o/{ns}/{path...}        删对象
 *   GET    /v1/list/{ns}?prefix=logs/  列对象
 *   GET    /health                     健康检查
 * 鉴权：Authorization: Bearer {ns}；ns 同时充当命名空间与访问凭据。
 */

interface Env {
  BUCKET: R2Bucket;
}

const NS_PATTERN = /^[a-z2-7]{26}$/;
const PATH_PATTERN = /^[A-Za-z0-9._/-]+$/;
const MAX_OBJECT_SIZE = 8 * 1024 * 1024;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === '/health') {
      return new Response('ok', { status: 200 });
    }

    const auth = request.headers.get('Authorization') ?? '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!NS_PATTERN.test(token)) {
      return json({ error: 'unauthorized' }, 401);
    }

    const listMatch = url.pathname.match(/^\/v1\/list\/([^/]+)\/?$/);
    if (listMatch && request.method === 'GET') {
      if (listMatch[1] !== token) {
        return json({ error: 'forbidden' }, 403);
      }
      const prefix = url.searchParams.get('prefix') ?? '';
      if (prefix.includes('..')) {
        return json({ error: 'bad prefix' }, 400);
      }
      const listed = await env.BUCKET.list({ prefix: `${token}/${prefix}` });
      return json({
        files: listed.objects.map((object) => ({
          path: object.key.slice(token.length + 1),
          size: object.size,
          etag: object.etag,
          modified: object.uploaded?.toISOString() ?? null,
        })),
      });
    }

    const objectMatch = url.pathname.match(/^\/v1\/o\/([^/]+)\/(.+)$/);
    if (objectMatch) {
      const [, namespace, rawPath] = objectMatch;
      if (namespace !== token) {
        return json({ error: 'forbidden' }, 403);
      }
      if (!PATH_PATTERN.test(rawPath) || rawPath.includes('..')) {
        return json({ error: 'bad path' }, 400);
      }
      const key = `${namespace}/${rawPath}`;

      if (request.method === 'GET') {
        const object = await env.BUCKET.get(key);
        if (!object) {
          return new Response('not found', { status: 404 });
        }
        return new Response(object.body, {
          status: 200,
          headers: {
            'Content-Type': 'application/octet-stream',
            ETag: object.httpEtag,
          },
        });
      }

      if (request.method === 'PUT') {
        const body = new Uint8Array(await request.arrayBuffer());
        if (body.byteLength === 0 || body.byteLength > MAX_OBJECT_SIZE) {
          return json({ error: 'bad size' }, 413);
        }
        // 日志与快照只写一次：已存在就拒绝，避免覆盖别人的数据。
        const existing = await env.BUCKET.head(key);
        if (existing) {
          return json({ error: 'exists' }, 409);
        }
        await env.BUCKET.put(key, body);
        return json({ ok: true }, 201);
      }

      if (request.method === 'DELETE') {
        await env.BUCKET.delete(key);
        return new Response(null, { status: 204 });
      }

      return json({ error: 'method not allowed' }, 405);
    }

    return json({ error: 'not found' }, 404);
  },
};

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
