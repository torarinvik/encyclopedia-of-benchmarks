#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kScale = 1'000'000;
constexpr std::int64_t kMaxFaceValueMicro = 1'000'000'000'000;
constexpr std::int64_t kMaxRateMicro = 1'000'000;
constexpr std::int64_t kMaxPeriods = 64;
constexpr std::size_t kMaxInputLength = 5;
constexpr double kInvalidResult = -1.0e300;
}

extern "C" double macaulay_duration(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4 || length > kMaxInputLength) return kInvalidResult;
    const auto face_micro=values[0], coupon_micro=values[1], periods=values[2], yield_micro=values[3];
    if (face_micro<1 || face_micro>kMaxFaceValueMicro || coupon_micro<0 || coupon_micro>kMaxRateMicro
            || periods<1 || periods>kMaxPeriods || yield_micro<1 || yield_micro>kMaxRateMicro) return kInvalidResult;
    const double face_value=static_cast<double>(face_micro)/static_cast<double>(kScale);
    const double coupon_rate=static_cast<double>(coupon_micro)/static_cast<double>(kScale);
    const double yield_rate=static_cast<double>(yield_micro)/static_cast<double>(kScale);
    double total_present_value=0.0, total_time_weighted_value=0.0;
    for (std::int64_t period=1; period<=periods; ++period) {
        const double cash_flow=face_value*coupon_rate+(period==periods?face_value:0.0);
        const double time_weighted_value=(static_cast<double>(period)*cash_flow)/std::pow(1.0+yield_rate,static_cast<double>(period));
        total_time_weighted_value+=time_weighted_value;
        const double present_value=cash_flow/std::pow(1.0+yield_rate,static_cast<double>(period));
        total_present_value+=present_value;
    }
    return total_time_weighted_value/total_present_value;
}
