module fourier_motzkin_feasibility;

const usz MAX_VARS = 3;
const usz MAX_INEQUALITIES = 6;
const usz MAX_ROWS = 128;
const usz MAX_PARSEABLE = 27;
const usz ROW_WIDTH = 4;

fn long fourier_motzkin_feasibility(long* input, usz length)
    @export("fourier_motzkin_feasibility") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    long dimension_value = input[0];
    long count_value = input[1];
    if (dimension_value < 1 || dimension_value > MAX_VARS.long() ||
        count_value < 1 || count_value > MAX_INEQUALITIES.long()) return -1;
    usz dimension = dimension_value.usz();
    usz count = count_value.usz();
    if (length != 2 + count * (dimension + 1)) return -1;

    long[MAX_ROWS * ROW_WIDTH] current = zeroed;
    long[MAX_ROWS * ROW_WIDTH] next = zeroed;
    usz offset = 2;
    for (usz row = 0; row < count; row++) {
        for (usz coordinate = 0; coordinate < dimension; coordinate++) {
            long value = input[offset];
            offset += 1;
            if (value < -3 || value > 3) return -1;
            current[row * ROW_WIDTH + coordinate] = value;
        }
        long bound = input[offset];
        offset += 1;
        if (bound < -6 || bound > 6) return -1;
        current[row * ROW_WIDTH + 3] = bound;
    }

    usz row_count = count;
    for (usz variable = 0; variable < dimension; variable++) {
        usz next_count = 0;
        for (usz row = 0; row < row_count; row++) {
            if (current[row * ROW_WIDTH + variable] == 0) {
                for (usz column = 0; column < ROW_WIDTH; column++)
                    next[next_count * ROW_WIDTH + column] = current[row * ROW_WIDTH + column];
                next_count += 1;
            }
        }
        for (usz upper = 0; upper < row_count; upper++) {
            long positive = current[upper * ROW_WIDTH + variable];
            if (positive <= 0) continue;
            for (usz lower = 0; lower < row_count; lower++) {
                long negative = current[lower * ROW_WIDTH + variable];
                if (negative >= 0) continue;
                if (next_count >= MAX_ROWS) return -1;
                long upper_scale = positive;
                long lower_scale = -negative;
                for (usz coordinate = 0; coordinate < dimension; coordinate++) {
                    next[next_count * ROW_WIDTH + coordinate] = coordinate == variable ? 0 :
                        lower_scale * current[upper * ROW_WIDTH + coordinate] +
                        upper_scale * current[lower * ROW_WIDTH + coordinate];
                }
                next[next_count * ROW_WIDTH + 3] = lower_scale * current[upper * ROW_WIDTH + 3] +
                                                   upper_scale * current[lower * ROW_WIDTH + 3];
                next_count += 1;
            }
        }
        for (usz row = 0; row < next_count; row++) {
            for (usz column = 0; column < ROW_WIDTH; column++) {
                current[row * ROW_WIDTH + column] = next[row * ROW_WIDTH + column];
                next[row * ROW_WIDTH + column] = 0;
            }
        }
        row_count = next_count;
    }
    for (usz row = 0; row < row_count; row++)
        if (current[row * ROW_WIDTH + 3] < 0) return 0;
    return 1;
}
