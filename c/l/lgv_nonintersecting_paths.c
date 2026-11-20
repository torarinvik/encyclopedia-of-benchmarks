#include <stddef.h>
#include <stdint.h>

#define LGV_MAX_HEIGHT 5
#define LGV_MAX_WIDTH 5
#define LGV_MAX_PATHS 3
#define LGV_MAX_PARSEABLE_LENGTH 11

static int64_t lgv_single_source_paths(int height, int width, int64_t blocked,
                                       int source_row, int sink_row) {
    int64_t ways[LGV_MAX_HEIGHT][LGV_MAX_WIDTH] = {{0}};
    for (int row = 0; row < height; ++row) {
        for (int column = 0; column < width; ++column) {
            const int bit = row * width + column;
            if (((blocked >> bit) & 1) != 0) {
                ways[row][column] = 0;
            } else if (row == source_row && column == 0) {
                ways[row][column] = 1;
            } else {
                const int64_t from_above = row > 0 ? ways[row - 1][column] : 0;
                const int64_t from_left = column > 0 ? ways[row][column - 1] : 0;
                ways[row][column] = from_above + from_left;
            }
        }
    }
    return ways[sink_row][width - 1];
}

static int64_t lgv_determinant(const int64_t matrix[LGV_MAX_PATHS][LGV_MAX_PATHS],
                               int order) {
    static const int permutations[6][3] = {
        {0, 1, 2}, {1, 0, 2}, {0, 2, 1},
        {1, 2, 0}, {2, 0, 1}, {2, 1, 0}
    };
    static const int signs[6] = {1, -1, -1, 1, 1, -1};
    const int permutation_count = order == 1 ? 1 : (order == 2 ? 2 : 6);
    int64_t determinant = 0;
    for (int p = 0; p < permutation_count; ++p) {
        int64_t term = 1;
        for (int row = 0; row < order; ++row)
            term *= matrix[row][permutations[p][row]];
        determinant += signs[p] * term;
    }
    return determinant;
}

int64_t lgv_nonintersecting_paths(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > LGV_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t raw_height = input[0];
    const int64_t raw_width = input[1];
    const int64_t raw_path_count = input[2];
    const int64_t blocked = input[3];
    if (raw_height < 1 || raw_height > LGV_MAX_HEIGHT ||
        raw_width < 2 || raw_width > LGV_MAX_WIDTH ||
        raw_path_count < 1 || raw_path_count > LGV_MAX_PATHS || blocked < 0)
        return -1;

    const int height = (int)raw_height;
    const int width = (int)raw_width;
    const int path_count = (int)raw_path_count;
    const size_t expected_length = (size_t)(4 + 2 * path_count);
    if (length != expected_length) return -1;
    const int cell_count = height * width;
    if (blocked >= (INT64_C(1) << cell_count)) return -1;

    int source_rows[LGV_MAX_PATHS];
    int sink_rows[LGV_MAX_PATHS];
    for (int i = 0; i < path_count; ++i) {
        const int64_t source = input[4 + i];
        const int64_t sink = input[4 + path_count + i];
        if (source < 0 || source >= height || sink < 0 || sink >= height ||
            source > sink)
            return -1;
        if (i > 0 && (source <= source_rows[i - 1] || sink <= sink_rows[i - 1]))
            return -1;
        source_rows[i] = (int)source;
        sink_rows[i] = (int)sink;
        const int source_bit = source_rows[i] * width;
        const int sink_bit = sink_rows[i] * width + width - 1;
        if (((blocked >> source_bit) & 1) != 0 || ((blocked >> sink_bit) & 1) != 0)
            return -1;
    }

    int64_t path_matrix[LGV_MAX_PATHS][LGV_MAX_PATHS] = {{0}};
    for (int source_index = 0; source_index < path_count; ++source_index) {
        for (int sink_index = 0; sink_index < path_count; ++sink_index) {
            path_matrix[source_index][sink_index] = lgv_single_source_paths(
                height, width, blocked, source_rows[source_index], sink_rows[sink_index]);
        }
    }
    return lgv_determinant(path_matrix, path_count);
}
