#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxCashFlows = 8;
constexpr std::int64_t kMaxRatePpm = 1'000'000;
constexpr std::int64_t kMaxCashFlowMilli = 1'000'000;
constexpr std::size_t kMaxInputLength = 11;
constexpr double kInvalidResult = -1.0e300;
}

extern "C" double present_value_rust(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > kMaxInputLength) return kInvalidResult;
    const std::int64_t count = values[0];
    const std::int64_t rate_ppm = values[1];
    if (count < 1 || count > kMaxCashFlows || length != static_cast<std::size_t>(count) + 2 ||
        (rate_ppm != 0 && rate_ppm != kMaxRatePpm)) return kInvalidResult;

    const double discount_rate = static_cast<double>(rate_ppm) / 1'000'000.0;
    double present_value = 0.0;
    for (std::int64_t index = 0; index < count; ++index) {
        const std::int64_t cash_flow_milli = values[static_cast<std::size_t>(index) + 2];
        if (cash_flow_milli < -kMaxCashFlowMilli || cash_flow_milli > kMaxCashFlowMilli ||
            cash_flow_milli % 125 != 0)
            return kInvalidResult;
        const double cash_flow = static_cast<double>(cash_flow_milli) / 1'000.0;
        present_value += cash_flow / std::pow(1.0 + discount_rate, static_cast<double>(index));
    }
    return std::round(present_value * 100.0) / 100.0;
}
