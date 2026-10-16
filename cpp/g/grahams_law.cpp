#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

static double rounded_six(double value) {
    if (!(value >= 0.0 && value <= 1.0e6)) return -1.0e300;
    double scaled = value * 1000000.0, lower = std::floor(scaled);
    double fraction = scaled - lower;
    if (fraction >= 0.499 && fraction <= 0.501) return -1.0e300;
    if (fraction > 0.5) lower += 1.0;
    return lower / 1000000.0;
}
static double decode_positive(const std::int64_t *values, std::size_t index) {
    double result;
    std::memcpy(&result, &values[index], sizeof(result));
    return std::isfinite(result) && result >= 1.0e-6 && result <= 1.0e6 ? result : 0.0;
}
extern "C" double grahams_law(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 3 || length > 4 || values[0] < 0 || values[0] > 4) return -1.0e300;
    const std::int64_t operation = values[0];
    if ((operation == 0 && length != 3) || (operation != 0 && length != 4)) return -1.0e300;
    const double first = decode_positive(values, 1), second = decode_positive(values, 2);
    if (first == 0.0 || second == 0.0) return -1.0e300;
    double result;
    if (operation == 0) result = std::sqrt(second / first);
    else {
        const double third = decode_positive(values, 3);
        if (third == 0.0) return -1.0e300;
        if (operation == 1) result = first * std::sqrt(third / second);
        else if (operation == 2) result = first / std::sqrt(third / second);
        else if (operation == 3) result = first / std::pow(second / third, 2.0);
        else result = std::pow(second / third, 2.0) / first;
    }
    return rounded_six(result);
}
