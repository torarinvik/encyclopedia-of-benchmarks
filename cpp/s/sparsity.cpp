#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 63;
constexpr std::size_t max_input_values = 2 + max_dimension * max_dimension;
constexpr std::int64_t max_abs_cell = 1'000'000;
constexpr double invalid_result = -1.0e300;
}

extern "C" double sparsity(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return invalid_result;
    const auto rows_value = input[0];
    const auto columns_value = input[1];
    if (rows_value < 1 || rows_value > static_cast<std::int64_t>(max_dimension) ||
        columns_value < 1 || columns_value > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto total = rows * columns;
    if (length != 2 + total) return invalid_result;

    std::size_t zero_count = 0;
    for (std::size_t index = 0; index < total; ++index) {
        const auto value = input[2 + index];
        if (value < -max_abs_cell || value > max_abs_cell) return invalid_result;
        if (value == 0) ++zero_count;
    }
    return static_cast<double>(zero_count) / static_cast<double>(total);
}
