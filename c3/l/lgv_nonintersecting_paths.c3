module lgv_nonintersecting_paths;

const int MAX_HEIGHT = 5;
const int MAX_WIDTH = 5;
const int MAX_PATHS = 3;
const usz MAX_PARSEABLE_LENGTH = 11;

fn long single_source_paths(int height, int width, long blocked, int source_row, int sink_row) {
    long[MAX_HEIGHT][MAX_WIDTH] ways = zeroed;
    for (int row = 0; row < height; row++) {
        for (int column = 0; column < width; column++) {
            int bit = row * width + column;
            if (((blocked >> bit) & 1) != 0) {
                ways[row][column] = 0;
            } else if (row == source_row && column == 0) {
                ways[row][column] = 1;
            } else {
                long from_above = row > 0 ? ways[row - 1][column] : 0;
                long from_left = column > 0 ? ways[row][column - 1] : 0;
                ways[row][column] = from_above + from_left;
            }
        }
    }
    return ways[sink_row][width - 1];
}

fn long determinant(long* matrix, int order) {
    int[18] permutations = {0, 1, 2, 1, 0, 2, 0, 2, 1,
                            1, 2, 0, 2, 0, 1, 2, 1, 0};
    int[6] signs = {1, -1, -1, 1, 1, -1};
    int permutation_count = order == 1 ? 1 : (order == 2 ? 2 : 6);
    long result = 0;
    for (int p = 0; p < permutation_count; p++) {
        long term = 1;
        for (int row = 0; row < order; row++)
            term *= matrix[row * 3 + permutations[p * 3 + row]];
        result += signs[p] * term;
    }
    return result;
}

fn long lgv_nonintersecting_paths(long* input, usz length)
        @export("lgv_nonintersecting_paths") {
    if (input == null || length < 4 || length > MAX_PARSEABLE_LENGTH) return -1;
    long raw_height = input[0];
    long raw_width = input[1];
    long raw_path_count = input[2];
    long blocked = input[3];
    if (raw_height < 1 || raw_height > MAX_HEIGHT || raw_width < 2 || raw_width > MAX_WIDTH ||
        raw_path_count < 1 || raw_path_count > MAX_PATHS || blocked < 0) return -1;
    int height = (int)raw_height;
    int width = (int)raw_width;
    int path_count = (int)raw_path_count;
    if (length != 4 + 2 * (usz)path_count) return -1;
    int cell_count = height * width;
    if (blocked >= (1l << cell_count)) return -1;

    int[MAX_PATHS] source_rows = zeroed;
    int[MAX_PATHS] sink_rows = zeroed;
    for (int i = 0; i < path_count; i++) {
        long source = input[4 + i];
        long sink = input[4 + path_count + i];
        if (source < 0 || source >= height || sink < 0 || sink >= height || source > sink)
            return -1;
        if (i > 0 && (source <= source_rows[i - 1] || sink <= sink_rows[i - 1])) return -1;
        source_rows[i] = (int)source;
        sink_rows[i] = (int)sink;
        int source_bit = source_rows[i] * width;
        int sink_bit = sink_rows[i] * width + width - 1;
        if (((blocked >> source_bit) & 1) != 0 || ((blocked >> sink_bit) & 1) != 0)
            return -1;
    }

    long[9] path_matrix = zeroed;
    for (int source_index = 0; source_index < path_count; source_index++) {
        for (int sink_index = 0; sink_index < path_count; sink_index++) {
            path_matrix[source_index * 3 + sink_index] = single_source_paths(
                height, width, blocked, source_rows[source_index], sink_rows[sink_index]);
        }
    }
    return determinant(&path_matrix[0], path_count);
}
