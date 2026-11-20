#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_variables = 3;
constexpr std::size_t max_inequalities = 6;
constexpr std::size_t max_rows = 128;
constexpr std::size_t max_parseable_length = 27;
constexpr std::size_t row_width = 4;
using Row = std::array<std::int64_t, row_width>;
}

extern "C" std::int64_t fourier_motzkin_feasibility(const std::int64_t* input,
                                                    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_length) return -1;
    const auto dimension_value = input[0];
    const auto count_value = input[1];
    if (dimension_value < 1 || dimension_value > static_cast<std::int64_t>(max_variables) ||
        count_value < 1 || count_value > static_cast<std::int64_t>(max_inequalities)) return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + count * (dimension + 1)) return -1;

    std::array<Row, max_rows> current{};
    std::array<Row, max_rows> next{};
    std::size_t offset = 2;
    for (std::size_t row = 0; row < count; ++row) {
        for (std::size_t coordinate = 0; coordinate < dimension; ++coordinate) {
            const auto value = input[offset++];
            if (value < -3 || value > 3) return -1;
            current[row][coordinate] = value;
        }
        const auto bound = input[offset++];
        if (bound < -6 || bound > 6) return -1;
        current[row][3] = bound;
    }

    std::size_t row_count = count;
    for (std::size_t variable = 0; variable < dimension; ++variable) {
        std::size_t next_count = 0;
        for (std::size_t row = 0; row < row_count; ++row) {
            if (current[row][variable] == 0) next[next_count++] = current[row];
        }
        for (std::size_t upper = 0; upper < row_count; ++upper) {
            const auto positive = current[upper][variable];
            if (positive <= 0) continue;
            for (std::size_t lower = 0; lower < row_count; ++lower) {
                const auto negative = current[lower][variable];
                if (negative >= 0) continue;
                if (next_count >= max_rows) return -1;
                const auto upper_scale = positive;
                const auto lower_scale = -negative;
                for (std::size_t coordinate = 0; coordinate < dimension; ++coordinate)
                    next[next_count][coordinate] = coordinate == variable ? 0 :
                        lower_scale * current[upper][coordinate] +
                        upper_scale * current[lower][coordinate];
                next[next_count][3] = lower_scale * current[upper][3] +
                                      upper_scale * current[lower][3];
                ++next_count;
            }
        }
        for (std::size_t row = 0; row < next_count; ++row) {
            current[row] = next[row];
            next[row].fill(0);
        }
        row_count = next_count;
    }
    for (std::size_t row = 0; row < row_count; ++row)
        if (current[row][3] < 0) return 0;
    return 1;
}
