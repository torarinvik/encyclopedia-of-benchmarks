const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 8;
const NO_FEASIBLE: i64 = -1025;
const INVALID_INPUT: i64 = -1026;

fn bestSubarrayAtMost(values: [MAX_COLUMNS]i64, count: usize, limit: i64) i64 {
    var prefixes: [MAX_COLUMNS + 1]i64 = @splat(0);
    var prefix_count: usize = 1;
    var running: i64 = 0;
    var best: i64 = NO_FEASIBLE;
    for (0..count) |i| {
        running += values[i];
        const threshold = running - limit;
        var low: usize = 0;
        var high = prefix_count;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (prefixes[middle] < threshold) low = middle + 1 else high = middle;
        }
        if (low < prefix_count) {
            const candidate = running - prefixes[low];
            if (best == NO_FEASIBLE or candidate > best) best = candidate;
        }
        var insert = prefix_count;
        while (insert > 0 and prefixes[insert - 1] > running) : (insert -= 1) {
            prefixes[insert] = prefixes[insert - 1];
        }
        prefixes[insert] = running;
        prefix_count += 1;
    }
    return best;
}

export fn max_sum_rectangle_no_larger_than_k(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 68) return INVALID_INPUT;
    const input = input_opt.?;
    const rows_value = input[0];
    const columns_value = input[1];
    const limit = input[2];
    if (rows_value < 1 or rows_value > MAX_ROWS or columns_value < 1 or columns_value > MAX_COLUMNS
        or limit < -1024 or limit > 1024) return INVALID_INPUT;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    if (length != 3 + rows * columns) return INVALID_INPUT;

    var matrix: [MAX_ROWS][MAX_COLUMNS]i64 = @splat(@splat(0));
    for (0..rows) |row| {
        for (0..columns) |column| {
            const value = input[3 + row * columns + column];
            if (value < -16 or value > 16) return INVALID_INPUT;
            matrix[row][column] = value;
        }
    }
    const short_dimension = @min(rows, columns);
    const long_dimension = @max(rows, columns);
    var best: i64 = NO_FEASIBLE;
    for (0..short_dimension) |first| {
        var compressed: [MAX_COLUMNS]i64 = @splat(0);
        for (first..short_dimension) |last| {
            for (0..long_dimension) |offset| {
                compressed[offset] += if (rows <= columns)
                    matrix[last][offset]
                else
                    matrix[offset][last];
            }
            const candidate = bestSubarrayAtMost(compressed, long_dimension, limit);
            if (candidate != NO_FEASIBLE and (best == NO_FEASIBLE or candidate > best)) {
                best = candidate;
                if (best == limit) return best;
            }
        }
    }
    return best;
}
