module landau_vishkin_k_difference_pattern_matching;

const usz MAX_PATTERN = 16;
const usz MAX_TEXT = 32;
const usz MAX_ERRORS = 2;
const usz MAX_VALID_INPUT = 3 + MAX_PATTERN + MAX_TEXT;
const usz MAX_PARSEABLE_INPUT = MAX_VALID_INPUT + 1;
const usz DIAGONALS = MAX_TEXT + MAX_ERRORS + 3;
const usz COSTS = MAX_ERRORS + 2;

fn usz slot(long diagonal) {
    return (usz)(diagonal + (long)MAX_ERRORS + 1);
}

fn long landau_vishkin_k_difference_pattern_matching(
    long* input, usz length, char* output, usz capacity
) @export("landau_vishkin_k_difference_pattern_matching") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    long raw_m = input[0];
    long raw_n = input[1];
    long raw_k = input[2];
    if (raw_m < 1 || raw_m > (long)MAX_PATTERN || raw_n < 0 ||
        raw_n > (long)MAX_TEXT || raw_k < 0 || raw_k > (long)MAX_ERRORS ||
        raw_k >= raw_m) return -1;
    usz m = (usz)raw_m;
    usz n = (usz)raw_n;
    usz k = (usz)raw_k;
    if (length != 3 + m + n) return -1;
    long* pattern = input + 3;
    long* text = pattern + m;
    for (usz index = 0; index < m + n; index += 1) {
        long symbol = index < m ? pattern[index] : text[index - m];
        if (symbol < 0 || symbol > 3) return -1;
    }
    if (output == null || capacity < n) return -2;

    long[DIAGONALS * COSTS] frontier = {};
    for (usz index = 0; index < DIAGONALS * COSTS; index += 1) {
        frontier[index] = -1;
    }
    long low = -((long)k + 1);
    for (long diagonal = low; diagonal < 0; diagonal += 1) {
        long magnitude = -diagonal;
        usz base = slot(diagonal) * COSTS;
        frontier[base + (usz)magnitude] = magnitude - 1;
        frontier[base + (usz)(magnitude - 1)] = magnitude - 2;
    }

    uchar[MAX_TEXT] staged = {};
    for (long errors = 0; errors <= (long)k; errors += 1) {
        for (long diagonal = -errors; diagonal <= raw_n; diagonal += 1) {
            usz base = slot(diagonal) * COSTS;
            long row = frontier[base + (usz)errors] + 1;
            long from_left = frontier[base - COSTS + (usz)errors];
            long from_right = frontier[base + COSTS + (usz)errors] + 1;
            if (from_left > row) row = from_left;
            if (from_right > row) row = from_right;
            if (row > raw_m) row = raw_m;
            while (row < raw_m) {
                long text_index = row + diagonal;
                if (text_index < 0 || text_index >= raw_n ||
                    pattern[row] != text[text_index]) break;
                row += 1;
            }
            frontier[base + (usz)(errors + 1)] = row;
            if (row == raw_m) {
                long endpoint = diagonal + raw_m;
                if (endpoint >= 1 && endpoint <= raw_n) {
                    staged[(usz)(endpoint - 1)] = 1;
                }
            }
        }
    }
    for (usz index = 0; index < n; index += 1) output[index] = (char)staged[index];
    return (long)n;
}
