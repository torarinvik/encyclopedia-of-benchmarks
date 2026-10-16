const MAX_SERIES_LENGTH: i64 = 16;
const MAX_SAMPLE_VALUE: i64 = 1_000;
const INVALID_RESULT: f64 = -1.0e300;
const UNREACHABLE: f64 = 1.0e300;

export fn dynamic_time_warping(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > 35) return INVALID_RESULT;
    const input = values.?;
    const first_length_value = input[0];
    const second_length_value = input[1];
    const band_value = input[2];
    if (first_length_value < 1 or first_length_value > MAX_SERIES_LENGTH or
        second_length_value < 1 or second_length_value > MAX_SERIES_LENGTH) return INVALID_RESULT;
    const first_length: usize = @intCast(first_length_value);
    const second_length: usize = @intCast(second_length_value);
    const difference = if (first_length_value > second_length_value)
        first_length_value - second_length_value else second_length_value - first_length_value;
    if (band_value < difference or band_value > MAX_SERIES_LENGTH or
        length != 3 + first_length + second_length) return INVALID_RESULT;
    const band: usize = @intCast(band_value);
    for (0..first_length + second_length) |index| {
        const value = input[3 + index];
        if (value < -MAX_SAMPLE_VALUE or value > MAX_SAMPLE_VALUE) return INVALID_RESULT;
    }

    var rows: [2][17]f64 = @splat(@splat(UNREACHABLE));
    for (0..second_length + 1) |column| rows[0][column] = UNREACHABLE;
    rows[0][0] = 0.0;
    for (1..first_length + 1) |row| {
        const current = row % 2;
        const previous = (row - 1) % 2;
        for (0..second_length + 1) |column| rows[current][column] = UNREACHABLE;
        const start = if (row > band) row - band else 1;
        const end = @min(second_length, row + band);
        for (start..end + 1) |column| {
            const difference_value = if (input[3 + row - 1] >= input[3 + first_length + column - 1])
                input[3 + row - 1] - input[3 + first_length + column - 1]
            else input[3 + first_length + column - 1] - input[3 + row - 1];
            var best = rows[previous][column];
            if (rows[current][column - 1] < best) best = rows[current][column - 1];
            if (rows[previous][column - 1] < best) best = rows[previous][column - 1];
            rows[current][column] = @as(f64, @floatFromInt(difference_value)) + best;
        }
    }
    return rows[first_length % 2][second_length];
}
