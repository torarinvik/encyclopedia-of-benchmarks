#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::int64_t invalid_result = std::numeric_limits<std::int64_t>::min();
}

extern "C" std::int64_t rsk_row_insertion(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_n + 2) return invalid_result;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_n)
        || length != static_cast<std::size_t>(n_value) + 1) return invalid_result;
    const auto n = static_cast<std::size_t>(n_value);

    std::array<bool, max_n> seen{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value < 0 || value >= n_value || seen[static_cast<std::size_t>(value)])
            return invalid_result;
        seen[static_cast<std::size_t>(value)] = true;
    }
    if (n == 0) return 0;

    std::array<std::int64_t, max_n * max_n> p{};
    std::array<std::int64_t, max_n * max_n> q{};
    std::array<std::size_t, max_n> row_lengths{};
    std::size_t row_count = 0;
    for (std::size_t step = 1; step <= n; ++step) {
        auto value = input[step] + 1;
        std::size_t row = 0;
        for (;;) {
            if (row == row_count) {
                p[row * max_n] = value;
                q[row * max_n] = static_cast<std::int64_t>(step);
                row_lengths[row] = 1;
                ++row_count;
                break;
            }
            std::size_t column = 0;
            while (column < row_lengths[row] && p[row * max_n + column] < value) ++column;
            if (column == row_lengths[row]) {
                p[row * max_n + column] = value;
                q[row * max_n + column] = static_cast<std::int64_t>(step);
                ++row_lengths[row];
                break;
            }
            const auto bumped = p[row * max_n + column];
            p[row * max_n + column] = value;
            value = bumped;
            ++row;
        }
    }

    std::array<std::int64_t, max_n> p_row{};
    std::array<std::int64_t, max_n> q_row{};
    for (std::size_t row = 0; row < row_count; ++row) {
        for (std::size_t column = 0; column < row_lengths[row]; ++column) {
            p_row[static_cast<std::size_t>(p[row * max_n + column] - 1)] = static_cast<std::int64_t>(row);
            q_row[static_cast<std::size_t>(q[row * max_n + column] - 1)] = static_cast<std::int64_t>(row);
        }
    }
    std::int64_t code = n_value;
    for (std::size_t label = 0; label < n; ++label) {
        code = code * 9 + p_row[label] + 1;
        code = code * 9 + q_row[label] + 1;
    }
    return code;
}
