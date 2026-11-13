#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::size_t max_input_length = 65;
constexpr std::int64_t invalid_result = INT64_MIN;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_input_length) return invalid_result;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n) return invalid_result;

    std::int64_t matrix[max_dimension * max_dimension]{};
    for (std::size_t index = 0; index < n * n; ++index) {
        const auto value = input[1 + index];
        if (value < -4 || value > 4) return invalid_result;
        matrix[index] = value;
    }

    std::int64_t sign = 1;
    std::int64_t previous_pivot = 1;
    for (std::size_t k = 0; k + 1 < n; ++k) {
        if (matrix[k * n + k] == 0) {
            std::size_t replacement = k + 1;
            while (replacement < n && matrix[replacement * n + k] == 0) ++replacement;
            if (replacement == n) return 0;
            for (std::size_t column = 0; column < n; ++column) {
                const auto temporary = matrix[k * n + column];
                matrix[k * n + column] = matrix[replacement * n + column];
                matrix[replacement * n + column] = temporary;
            }
            sign = -sign;
        }

        const auto pivot = matrix[k * n + k];
        for (std::size_t row = k + 1; row < n; ++row) {
            for (std::size_t column = k + 1; column < n; ++column) {
                const auto numerator = matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column];
                matrix[row * n + column] = numerator / previous_pivot;
            }
            matrix[row * n + k] = 0;
        }
        previous_pivot = pivot;
    }
    return sign * matrix[(n - 1) * n + n - 1];
}
}

extern "C" std::int64_t bareiss_determinant(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
