#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
}

extern "C" double transformations_2d(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 3) return invalid_result;
    const auto operation = values[0], parameter_micro = values[1], component = values[2];
    if (operation < 0 || operation > 3 || component < 0 || component > 3) return invalid_result;

    double matrix[4];
    if (operation == 0) {
        if (parameter_micro < -1000000 || parameter_micro > 1000000) return invalid_result;
        const double factor = static_cast<double>(parameter_micro) / 1000000.0;
        matrix[0] = factor * 1.0;
        matrix[1] = factor * 0.0;
        matrix[2] = factor * 0.0;
        matrix[3] = factor * 1.0;
    } else {
        if (parameter_micro < -6283185 || parameter_micro > 6283185) return invalid_result;
        const double angle = static_cast<double>(parameter_micro) / 1000000.0;
        const double c = std::cos(angle), s = std::sin(angle);
        if (operation == 1) {
            matrix[0] = c; matrix[1] = -s;
            matrix[2] = s; matrix[3] = c;
        } else {
            const double cs = c * s;
            if (operation == 2) {
                matrix[0] = c * c; matrix[1] = cs;
                matrix[2] = cs; matrix[3] = s * s;
            } else {
                matrix[0] = 2.0 * c - 1.0; matrix[1] = 2.0 * cs;
                matrix[2] = 2.0 * cs; matrix[3] = 2.0 * s - 1.0;
            }
        }
    }
    return matrix[component];
}
