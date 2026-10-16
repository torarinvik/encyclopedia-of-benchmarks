#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 32;
constexpr std::size_t max_input_length = 4 + 2 * max_dimension * max_dimension + 1;
}

extern "C" std::int64_t checkequal(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 4 || length > max_input_length) {
        return -1;
    }

    const std::int64_t rows_a = values[0];
    const std::int64_t columns_a = values[1];
    const std::int64_t rows_b = values[2];
    const std::int64_t columns_b = values[3];
    if (rows_a < 0 || rows_a > static_cast<std::int64_t>(max_dimension)
            || columns_a < 0 || columns_a > static_cast<std::int64_t>(max_dimension)
            || rows_b < 0 || rows_b > static_cast<std::int64_t>(max_dimension)
            || columns_b < 0 || columns_b > static_cast<std::int64_t>(max_dimension)) {
        return -1;
    }

    const std::size_t count_a = static_cast<std::size_t>(rows_a * columns_a);
    const std::size_t count_b = static_cast<std::size_t>(rows_b * columns_b);
    if (length != 4 + count_a + count_b) {
        return -1;
    }
    if (rows_a != rows_b || columns_a != columns_b) {
        return 0;
    }
    for (std::size_t index = 0; index < count_a; ++index) {
        if (values[4 + index] != values[4 + count_a + index]) {
            return 0;
        }
    }
    return 1;
}
