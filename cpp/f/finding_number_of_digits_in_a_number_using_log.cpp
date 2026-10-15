#include <cmath>

namespace {
constexpr double MAX_ABS_VALUE = 1000000.0;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double finding_number_of_digits_in_a_number_using_log(double value) noexcept
{
    if (!(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE)) return INVALID_RESULT;
    if (value == 0.0) return 0.0;
    return std::floor(std::log10(std::abs(value)) + 1.0);
}
