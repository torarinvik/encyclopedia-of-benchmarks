#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_height = 5;
constexpr int max_width = 5;
constexpr int max_paths = 3;
constexpr std::size_t max_parseable_length = 11;

std::int64_t single_source_paths(int height, int width, std::int64_t blocked,
                                 int source_row, int sink_row) noexcept {
    std::int64_t ways[max_height][max_width]{};
    for (int row = 0; row < height; ++row) {
        for (int column = 0; column < width; ++column) {
            const int bit = row * width + column;
            if (((blocked >> bit) & 1) != 0) {
                ways[row][column] = 0;
            } else if (row == source_row && column == 0) {
                ways[row][column] = 1;
            } else {
                const std::int64_t from_above = row > 0 ? ways[row - 1][column] : 0;
                const std::int64_t from_left = column > 0 ? ways[row][column - 1] : 0;
                ways[row][column] = from_above + from_left;
            }
        }
    }
    return ways[sink_row][width - 1];
}

std::int64_t determinant(const std::int64_t matrix[max_paths][max_paths], int order) noexcept {
    static constexpr int permutations[6][3] = {
        {0, 1, 2}, {1, 0, 2}, {0, 2, 1},
        {1, 2, 0}, {2, 0, 1}, {2, 1, 0}
    };
    static constexpr int signs[6] = {1, -1, -1, 1, 1, -1};
    const int permutation_count = order == 1 ? 1 : (order == 2 ? 2 : 6);
    std::int64_t result = 0;
    for (int p = 0; p < permutation_count; ++p) {
        std::int64_t term = 1;
        for (int row = 0; row < order; ++row)
            term *= matrix[row][permutations[p][row]];
        result += signs[p] * term;
    }
    return result;
}
} // namespace

extern "C" std::int64_t lgv_nonintersecting_paths(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_parseable_length) return -1;
    const std::int64_t raw_height = input[0];
    const std::int64_t raw_width = input[1];
    const std::int64_t raw_path_count = input[2];
    const std::int64_t blocked = input[3];
    if (raw_height < 1 || raw_height > max_height || raw_width < 2 || raw_width > max_width ||
        raw_path_count < 1 || raw_path_count > max_paths || blocked < 0)
        return -1;
    const int height = static_cast<int>(raw_height);
    const int width = static_cast<int>(raw_width);
    const int path_count = static_cast<int>(raw_path_count);
    if (length != static_cast<std::size_t>(4 + 2 * path_count)) return -1;
    const int cell_count = height * width;
    if (blocked >= (std::int64_t{1} << cell_count)) return -1;

    int source_rows[max_paths]{};
    int sink_rows[max_paths]{};
    for (int i = 0; i < path_count; ++i) {
        const std::int64_t source = input[4 + i];
        const std::int64_t sink = input[4 + path_count + i];
        if (source < 0 || source >= height || sink < 0 || sink >= height || source > sink)
            return -1;
        if (i > 0 && (source <= source_rows[i - 1] || sink <= sink_rows[i - 1])) return -1;
        source_rows[i] = static_cast<int>(source);
        sink_rows[i] = static_cast<int>(sink);
        const int source_bit = source_rows[i] * width;
        const int sink_bit = sink_rows[i] * width + width - 1;
        if (((blocked >> source_bit) & 1) != 0 || ((blocked >> sink_bit) & 1) != 0)
            return -1;
    }

    std::int64_t path_matrix[max_paths][max_paths]{};
    for (int source_index = 0; source_index < path_count; ++source_index) {
        for (int sink_index = 0; sink_index < path_count; ++sink_index) {
            path_matrix[source_index][sink_index] = single_source_paths(
                height, width, blocked, source_rows[source_index], sink_rows[sink_index]);
        }
    }
    return determinant(path_matrix, path_count);
}
