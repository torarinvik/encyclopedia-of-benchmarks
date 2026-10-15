#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
}

extern "C" double ncr_combinations(double total, double choose) noexcept {
    if (total != total || choose != choose || total < 0.0 || total > 20.0 ||
        choose < 0.0 || choose > 12.0 || choose != static_cast<double>(static_cast<std::int64_t>(choose))) {
        return invalid_result;
    }

    const auto count = static_cast<std::int64_t>(choose);
    double numerator = 1.0;
    for (std::int64_t index = 0; index < count; ++index) {
        numerator *= total - static_cast<double>(index);
    }
    double denominator = 1.0;
    for (std::int64_t factor = 2; factor <= count; ++factor) {
        denominator *= static_cast<double>(factor);
    }
    return numerator / denominator;
}
