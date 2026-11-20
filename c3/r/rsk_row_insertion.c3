module rsk_row_insertion;

const usz MAX_N = 8;
const long BASE = 9;
const long INVALID_RESULT = -9223372036854775807 - 1;

fn long rsk_row_insertion(long* input, usz length) @export("rsk_row_insertion") {
    if (input == null || length < 1 || length > 10) return INVALID_RESULT;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N || length != (usz)(n_value + 1))
        return INVALID_RESULT;
    usz n = (usz)n_value;
    bool[MAX_N] seen = zeroed;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value < 0 || value >= n_value || seen[(usz)value]) return INVALID_RESULT;
        seen[(usz)value] = true;
    }
    if (n == 0) return 0;

    long[MAX_N * MAX_N] p = zeroed;
    long[MAX_N * MAX_N] q = zeroed;
    usz[MAX_N] row_lengths = zeroed;
    usz row_count = 0;
    for (usz step = 1; step <= n; step += 1) {
        long value = input[step] + 1;
        usz row = 0;
        while (true) {
            if (row == row_count) {
                p[row * MAX_N] = value;
                q[row * MAX_N] = (long)step;
                row_lengths[row] = 1;
                row_count += 1;
                break;
            }
            usz column = 0;
            while (column < row_lengths[row] && p[row * MAX_N + column] < value)
                column += 1;
            if (column == row_lengths[row]) {
                p[row * MAX_N + column] = value;
                q[row * MAX_N + column] = (long)step;
                row_lengths[row] += 1;
                break;
            }
            long bumped = p[row * MAX_N + column];
            p[row * MAX_N + column] = value;
            value = bumped;
            row += 1;
        }
    }

    long[MAX_N] p_row = zeroed;
    long[MAX_N] q_row = zeroed;
    for (usz row = 0; row < row_count; row += 1) {
        for (usz column = 0; column < row_lengths[row]; column += 1) {
            p_row[(usz)(p[row * MAX_N + column] - 1)] = (long)row;
            q_row[(usz)(q[row * MAX_N + column] - 1)] = (long)row;
        }
    }
    long code = n_value;
    for (usz label = 0; label < n; label += 1) {
        code = code * BASE + p_row[label] + 1;
        code = code * BASE + q_row[label] + 1;
    }
    return code;
}
