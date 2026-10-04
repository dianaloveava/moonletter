import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import 'cycle_predictor.dart';
import 'prediction_config.dart';

/// 预测参数，跟随设置页「预测规则」分组。
final Provider<PredictionConfig> predictionConfigProvider =
    Provider<PredictionConfig>((Ref ref) {
      final AsyncValue<Map<String, String>> settings = ref.watch(
        settingsProvider,
      );
      final Map<String, String> values = switch (settings) {
        AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
        _ => const <String, String>{},
      };
      return PredictionConfig.fromSettings(values);
    });

/// 全部成员的全部未删除经期记录，按成员分组（按开始日升序）。
final StreamProvider<Map<String, List<Period>>> periodsByMemberProvider =
    StreamProvider<Map<String, List<Period>>>(
      (Ref ref) => ref.watch(periodRepositoryProvider).watchGrouped(),
    );

/// 每个成员的预测结果。没有记录的成员值为 null；数据未就绪时不含该成员。
final Provider<Map<String, Prediction?>> predictionsProvider =
    Provider<Map<String, Prediction?>>((Ref ref) {
      final PredictionConfig cfg = ref.watch(predictionConfigProvider);
      final AsyncValue<List<Member>> members = ref.watch(membersProvider);
      final AsyncValue<Map<String, List<Period>>> periods = ref.watch(
        periodsByMemberProvider,
      );
      final List<Member> list = switch (members) {
        AsyncData<List<Member>>(value: final List<Member> v) => v,
        _ => const <Member>[],
      };
      final Map<String, List<Period>> grouped = switch (periods) {
        AsyncData<Map<String, List<Period>>>(
          value: final Map<String, List<Period>> v,
        ) =>
          v,
        _ => const <String, List<Period>>{},
      };
      return <String, Prediction?>{
        for (final Member member in list)
          member.id: predict(
            member,
            grouped[member.id] ?? const <Period>[],
            cfg,
          ),
      };
    });
