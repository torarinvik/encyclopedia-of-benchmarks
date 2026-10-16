#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double component_limit = 1'000'000.0;
constexpr double epsilon = 1.0e-9;

float dot_product(const float a[3], const float b[3]) noexcept {
    float dot = a[0] * b[0];
    dot += a[1] * b[1];
    dot += a[2] * b[2];
    return dot;
}

float vector_norm(const float vector[3]) noexcept {
    return std::sqrt(dot_product(vector, vector));
}
}

extern "C" std::int64_t vectors_3d(const double *input, std::size_t input_len,
                                    double *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_len == 0 || !std::isfinite(input[0]) ||
        input[0] < 0.0 || input[0] > 7.0 || std::floor(input[0]) != input[0]) return -1;
    const int operation = static_cast<int>(input[0]);
    const std::size_t required_length = operation <= 3 || operation == 7 ? 7 : 4;
    if (input_len != required_length) return -1;

    float a[3], b[3] = {0.0f, 0.0f, 0.0f};
    for (std::size_t index = 0; index < 3; ++index) {
        const double value = input[1 + index];
        if (!std::isfinite(value) || std::fabs(value) > component_limit) return -1;
        a[index] = static_cast<float>(value);
    }
    if (required_length == 7) {
        for (std::size_t index = 0; index < 3; ++index) {
            const double value = input[4 + index];
            if (!std::isfinite(value) || std::fabs(value) > component_limit) return -1;
            b[index] = static_cast<float>(value);
        }
    }

    double result[9] = {};
    std::size_t result_length;
    switch (operation) {
        case 0:
            result_length = 3;
            for (std::size_t index = 0; index < 3; ++index) result[index] = static_cast<double>(a[index] + b[index]);
            break;
        case 1:
            result_length = 3;
            for (std::size_t index = 0; index < 3; ++index) result[index] = static_cast<double>(a[index] - b[index]);
            break;
        case 2:
            result_length = 1;
            result[0] = static_cast<double>(dot_product(a, b));
            break;
        case 3:
            result_length = 3;
            result[0] = static_cast<double>(a[1] * b[2] - a[2] * b[1]);
            result[1] = static_cast<double>(-a[0] * b[2] + a[2] * b[0]);
            result[2] = static_cast<double>(a[0] * b[1] - a[1] * b[0]);
            break;
        case 4:
            result_length = 1;
            result[0] = static_cast<double>(vector_norm(a));
            break;
        case 5: {
            result_length = 3;
            const float norm = vector_norm(a);
            if (norm < epsilon) break;
            // Preserve the source defect: exact unit input leaves the zero initializer intact.
            if (norm != 1.0f) {
                for (std::size_t index = 0; index < 3; ++index) result[index] = static_cast<double>(a[index] / norm);
            }
            break;
        }
        case 6:
            result_length = 9;
            result[0] = 0.0; result[1] = static_cast<double>(-a[2]); result[2] = static_cast<double>(a[1]);
            result[3] = static_cast<double>(a[2]); result[4] = 0.0; result[5] = static_cast<double>(-a[0]);
            result[6] = static_cast<double>(-a[1]); result[7] = static_cast<double>(a[0]); result[8] = 0.0;
            break;
        default: {
            result_length = 1;
            const float norm_a = vector_norm(a);
            const float norm_b = vector_norm(b);
            if (norm_a < epsilon || norm_b < epsilon) {
                result[0] = std::acos(2.0);
            } else {
                const float cosine = dot_product(a, b) / (norm_a * norm_b);
                result[0] = std::acos(static_cast<double>(cosine));
            }
            break;
        }
    }

    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return static_cast<std::int64_t>(result_length);
}
