#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr std::int64_t MAX_ENDPOINT_MILLI = 100000;

double equation(double x) { return 10.0 - x * x; }
}

extern "C" double bisection_2(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 2) return INVALID_RESULT;
    const auto left_milli = input[0], right_milli = input[1];
    if (left_milli < -MAX_ENDPOINT_MILLI || left_milli > MAX_ENDPOINT_MILLI
        || right_milli < -MAX_ENDPOINT_MILLI || right_milli > MAX_ENDPOINT_MILLI
        || left_milli >= right_milli) return INVALID_RESULT;
    double a = static_cast<double>(left_milli) / 1000.0;
    double b = static_cast<double>(right_milli) / 1000.0;
    if (equation(a) * equation(b) >= 0.0) return INVALID_RESULT;
    double c = a;
    while ((b - a) >= 0.01) {
        c = (a + b) / 2.0;
        if (equation(c) == 0.0) break;
        if (equation(c) * equation(a) < 0.0) b = c;
        else a = c;
    }
    return c;
}
