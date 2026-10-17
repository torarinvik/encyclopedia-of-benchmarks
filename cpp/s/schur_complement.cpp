#include <cstddef>
#include <cstdint>

extern "C" double schur_complement(const std::int64_t *input, std::size_t length) {
    constexpr double invalid = -1.0e300;
    if (input == nullptr || length != 6) return invalid;
    const std::int64_t a00 = input[0], a01 = input[1], a11 = input[2];
    const std::int64_t b0 = input[3], b1 = input[4], c00 = input[5];
    if (a00 < -8 || a00 > 8 || a01 < -8 || a01 > 8 || a11 < -8 || a11 > 8 ||
        b0 < -100 || b0 > 100 || b1 < -100 || b1 > 100 || c00 < -100 || c00 > 100) return invalid;
    const std::int64_t determinant = a00 * a11 - a01 * a01;
    if (determinant == 0) return invalid;
    const double inv00 = static_cast<double>(a11) / static_cast<double>(determinant);
    const double inv01 = -static_cast<double>(a01) / static_cast<double>(determinant);
    const double inv10 = -static_cast<double>(a01) / static_cast<double>(determinant);
    const double inv11 = static_cast<double>(a00) / static_cast<double>(determinant);
    const double left0 = static_cast<double>(b0) * inv00 + static_cast<double>(b1) * inv10;
    const double left1 = static_cast<double>(b0) * inv01 + static_cast<double>(b1) * inv11;
    const double quadratic = left0 * static_cast<double>(b0) + left1 * static_cast<double>(b1);
    return static_cast<double>(c00) - quadratic;
}
