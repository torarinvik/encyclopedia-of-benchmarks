#include <cmath>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ABS_VALUE = INT64_C(1000000);
}

extern "C" std::int64_t finding_number_of_digits_in_a_number_using_log(std::int64_t value) noexcept
{
    if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return -1;
    if (value == 0) return 0;
    const double magnitude = std::fabs(static_cast<double>(value));
    return static_cast<std::int64_t>(std::floor(std::log10(magnitude) + 1.0));
}
