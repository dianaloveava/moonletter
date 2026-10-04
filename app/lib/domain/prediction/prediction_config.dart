import '../../data/db/tables.dart';

/// 预测算法参数（§5.1）。默认 6 / 28 / 5 / 14 / 5 / 4，设置页「预测规则」分组可改。
class PredictionConfig {
  const PredictionConfig({
    this.window = 6,
    this.fallbackCycle = 28,
    this.fallbackPeriod = 5,
    this.ovulationOffset = 14,
    this.fertileBefore = 5,
    this.fertileAfter = 4,
  });

  /// 参与平均的最近记录条数。
  final int window;

  /// 记录不足以求平均时的周期天数。
  final int fallbackCycle;

  /// 记录不足以求平均时的经期天数。
  final int fallbackPeriod;

  /// 排卵日 = 下次开始日往前推的天数。
  final int ovulationOffset;

  /// 危险期起始 = 排卵日往前推的天数。
  final int fertileBefore;

  /// 危险期结束 = 排卵日往后推的天数。
  final int fertileAfter;

  /// 全部默认值。
  static const PredictionConfig fallback = PredictionConfig();

  /// 从 `settings` 表快照构造；缺失或非法的键退回默认值。
  factory PredictionConfig.fromSettings(Map<String, String> settings) {
    int read(String key, int defaultValue) =>
        int.tryParse(settings[key] ?? '') ?? defaultValue;
    return PredictionConfig(
      window: read(SettingKeys.predictionWindow, fallback.window),
      fallbackCycle: read(
        SettingKeys.predictionFallbackCycle,
        fallback.fallbackCycle,
      ),
      fallbackPeriod: read(
        SettingKeys.predictionFallbackPeriod,
        fallback.fallbackPeriod,
      ),
      ovulationOffset: read(
        SettingKeys.predictionOvulationOffset,
        fallback.ovulationOffset,
      ),
      fertileBefore: read(
        SettingKeys.predictionFertileBefore,
        fallback.fertileBefore,
      ),
      fertileAfter: read(
        SettingKeys.predictionFertileAfter,
        fallback.fertileAfter,
      ),
    );
  }
}
