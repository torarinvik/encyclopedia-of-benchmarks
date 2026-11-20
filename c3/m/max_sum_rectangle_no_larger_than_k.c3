module max_sum_rectangle_no_larger_than_k;

const usz MAX_ROWS = 8;
const usz MAX_COLUMNS = 8;
const usz MAX_PARSEABLE_LENGTH = 68;
const long NO_FEASIBLE = -1025L;
const long INVALID_INPUT = -1026L;

fn long best_subarray_at_most(long* values, usz count, long limit) {
    long[9] prefixes = zeroed;
    usz prefix_count = 1;
    long running = 0, best = NO_FEASIBLE;
    for (usz i = 0; i < count; i++) {
        running += values[i];
        long threshold = running - limit;
        usz low = 0, high = prefix_count;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (prefixes[middle] < threshold) low = middle + 1;
            else high = middle;
        }
        if (low < prefix_count) {
            long candidate = running - prefixes[low];
            if (best == NO_FEASIBLE || candidate > best) best = candidate;
        }
        usz insert = prefix_count;
        while (insert > 0 && prefixes[insert - 1] > running) {
            prefixes[insert] = prefixes[insert - 1];
            insert--;
        }
        prefixes[insert] = running;
        prefix_count++;
    }
    return best;
}

fn long max_sum_rectangle_no_larger_than_k(long* input, usz length)
        @export("max_sum_rectangle_no_larger_than_k") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return INVALID_INPUT;
    long rows_value = input[0], columns_value = input[1], limit = input[2];
    if (rows_value < 1 || rows_value > (long)MAX_ROWS
        || columns_value < 1 || columns_value > (long)MAX_COLUMNS
        || limit < -1024 || limit > 1024) return INVALID_INPUT;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    if (length != 3 + rows * columns) return INVALID_INPUT;
    long[64] matrix = zeroed;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long value = input[3 + row * columns + column];
            if (value < -16 || value > 16) return INVALID_INPUT;
            matrix[row * MAX_COLUMNS + column] = value;
        }
    }
    usz short_dimension = rows < columns ? rows : columns;
    usz long_dimension = rows < columns ? columns : rows;
    long best = NO_FEASIBLE;
    for (usz first = 0; first < short_dimension; first++) {
        long[8] compressed = zeroed;
        for (usz last = first; last < short_dimension; last++) {
            for (usz offset = 0; offset < long_dimension; offset++) {
                usz index = rows <= columns
                    ? last * MAX_COLUMNS + offset
                    : offset * MAX_COLUMNS + last;
                compressed[offset] += matrix[index];
            }
            long candidate = best_subarray_at_most(&compressed[0], long_dimension, limit);
            if (candidate != NO_FEASIBLE && (best == NO_FEASIBLE || candidate > best)) {
                best = candidate;
                if (best == limit) return best;
            }
        }
    }
    return best;
}
