#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_rows = 32;
constexpr std::size_t max_columns = 32;
constexpr std::size_t max_input_length = 2 + max_rows * max_columns + 1;
constexpr std::int64_t max_amount = 1'000'000;
}

extern "C" std::int64_t richest_customer_wealth(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_rows) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_columns)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    if (length != 2 + rows * columns) return -1;
    std::int64_t richest = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        std::int64_t wealth = 0;
        for (std::size_t column = 0; column < columns; ++column) {
            const auto amount = input[2 + row * columns + column];
            if (amount < 0 || amount > max_amount) return -1;
            wealth += amount;
        }
        if (wealth > richest) richest = wealth;
    }
    return richest;
}
