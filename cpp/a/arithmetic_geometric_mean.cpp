#include <cmath>

namespace {
constexpr double MAX_VALUE = 1000000.0;
constexpr double INVALID_RESULT = -1.0;
}

extern "C" double arithmetic_geometric_mean(double first, double second) noexcept
{
    if (std::isnan(first) || std::isnan(second) || first < 0.0 || second < 0.0 ||
        first > MAX_VALUE || second > MAX_VALUE) return INVALID_RESULT;
    if (first == second) return first;

    double arithmetic = first;
    double geometric = second;
    double previous;
    do {
        previous = arithmetic;
        const double next_arithmetic = (arithmetic + geometric) / 2.0;
        const double next_geometric = std::sqrt(arithmetic * geometric);
        arithmetic = next_arithmetic;
        geometric = next_geometric;
    } while (arithmetic != previous);
    return arithmetic;
}
