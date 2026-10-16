/* Port of the pinned Java TimeConverter conversion factors and rounding. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kScale = 1'000'000;
constexpr std::int64_t kMaxTimeMicro = 1'000'000'000;
constexpr std::size_t kMaxInputLength = 4;
constexpr double kInvalidResult = -1.0e300;

double seconds_per_unit(std::int64_t unit) {
    switch (unit) {
        case 0: return 1.0;
        case 1: return 60.0;
        case 2: return 3600.0;
        case 3: return 86400.0;
        case 4: return 604800.0;
        case 5: return 2629800.0;
        case 6: return 31557600.0;
        default: return 0.0;
    }
}
}

extern "C" double time_converter(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3 || length > kMaxInputLength) return kInvalidResult;
    const auto time_micro = values[0], from_unit = values[1], to_unit = values[2];
    if (time_micro < 0 || time_micro > kMaxTimeMicro || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6)
        return kInvalidResult;
    const double time_value = static_cast<double>(time_micro) / static_cast<double>(kScale);
    const double seconds_value = time_value * seconds_per_unit(from_unit);
    const double converted = seconds_value / seconds_per_unit(to_unit);
    const auto rounded = static_cast<std::int64_t>(converted * 1000.0 + 0.5);
    return static_cast<double>(rounded) / 1000.0;
}
