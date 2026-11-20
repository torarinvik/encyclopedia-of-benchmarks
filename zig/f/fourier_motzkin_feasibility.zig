const MAX_VARIABLES: usize = 3;
const MAX_INEQUALITIES: usize = 6;
const MAX_ROWS: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 27;
const ROW_WIDTH: usize = 4;

export fn fourier_motzkin_feasibility(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const dimension_value = input[0];
    const count_value = input[1];
    if (dimension_value < 1 or dimension_value > @as(i64, @intCast(MAX_VARIABLES)) or
        count_value < 1 or count_value > @as(i64, @intCast(MAX_INEQUALITIES))) return -1;
    const dimension: usize = @intCast(dimension_value);
    const count: usize = @intCast(count_value);
    if (length != 2 + count * (dimension + 1)) return -1;

    var current: [MAX_ROWS * ROW_WIDTH]i64 = @splat(0);
    var next_rows: [MAX_ROWS * ROW_WIDTH]i64 = @splat(0);
    var offset: usize = 2;
    for (0..count) |row| {
        for (0..dimension) |coordinate| {
            const value = input[offset];
            offset += 1;
            if (value < -3 or value > 3) return -1;
            current[row * ROW_WIDTH + coordinate] = value;
        }
        const bound = input[offset];
        offset += 1;
        if (bound < -6 or bound > 6) return -1;
        current[row * ROW_WIDTH + 3] = bound;
    }

    var row_count = count;
    for (0..dimension) |variable| {
        var next_count: usize = 0;
        for (0..row_count) |row| {
            if (current[row * ROW_WIDTH + variable] == 0) {
                for (0..ROW_WIDTH) |column| {
                    next_rows[next_count * ROW_WIDTH + column] = current[row * ROW_WIDTH + column];
                }
                next_count += 1;
            }
        }
        for (0..row_count) |upper| {
            const positive = current[upper * ROW_WIDTH + variable];
            if (positive <= 0) continue;
            for (0..row_count) |lower| {
                const negative = current[lower * ROW_WIDTH + variable];
                if (negative >= 0) continue;
                if (next_count >= MAX_ROWS) return -1;
                const upper_scale = positive;
                const lower_scale = -negative;
                for (0..dimension) |coordinate| {
                    next_rows[next_count * ROW_WIDTH + coordinate] = if (coordinate == variable)
                        0
                    else
                        lower_scale * current[upper * ROW_WIDTH + coordinate] +
                            upper_scale * current[lower * ROW_WIDTH + coordinate];
                }
                next_rows[next_count * ROW_WIDTH + 3] =
                    lower_scale * current[upper * ROW_WIDTH + 3] +
                    upper_scale * current[lower * ROW_WIDTH + 3];
                next_count += 1;
            }
        }
        for (0..next_count) |row| {
            for (0..ROW_WIDTH) |column| {
                current[row * ROW_WIDTH + column] = next_rows[row * ROW_WIDTH + column];
                next_rows[row * ROW_WIDTH + column] = 0;
            }
        }
        row_count = next_count;
    }
    for (0..row_count) |row| {
        if (current[row * ROW_WIDTH + 3] < 0) return 0;
    }
    return 1;
}
