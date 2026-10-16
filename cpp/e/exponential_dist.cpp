#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_RATE_MICRO = 1'000'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double exponential_dist(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const std::int64_t operation = values[0], rate_micro = values[1];
    if (operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > MAX_RATE_MICRO)
        return INVALID_RESULT;
    const double rate = static_cast<double>(rate_micro) / 1'000'000.0;
    if (operation == 1) return 1.0 / std::pow(rate, 2.0);
    return 1.0 / rate;
}
