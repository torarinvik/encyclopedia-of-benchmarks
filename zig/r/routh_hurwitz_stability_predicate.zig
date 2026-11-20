const MAX_DEGREE: i64 = 4;
const MAX_PARSEABLE_LENGTH: usize = 7;

pub export fn routh_hurwitz_stability_predicate(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = values.?;
    const degree = input[0];
    if (degree < 1 or degree > MAX_DEGREE or length != @as(usize, @intCast(degree)) + 2) return -1;

    var coefficients = [_]i64{0} ** 5;
    for (0..@as(usize, @intCast(degree)) + 1) |index| {
        const value = input[index + 1];
        if (value < -3 or value > 3 or (index == 0 and value <= 0)) return -1;
        coefficients[index] = value;
    }

    const width = (@as(usize, @intCast(degree)) + 2) / 2;
    var table = [_][3]i64{[_]i64{0} ** 3} ** 5;
    for (0..width) |column| {
        const even_index = 2 * column;
        const odd_index = even_index + 1;
        if (even_index <= @as(usize, @intCast(degree))) table[0][column] = coefficients[even_index];
        if (odd_index <= @as(usize, @intCast(degree))) table[1][column] = coefficients[odd_index];
    }
    var row_one_is_zero = true;
    for (0..width) |column| row_one_is_zero = row_one_is_zero and table[1][column] == 0;
    if (row_one_is_zero or table[1][0] <= 0) return 0;

    for (2..@as(usize, @intCast(degree)) + 1) |row| {
        if (table[row - 1][0] <= 0) return 0;
        var all_zero = true;
        for (0..width) |column| {
            const upper_next = if (column + 1 < width) table[row - 2][column + 1] else 0;
            const lower_next = if (column + 1 < width) table[row - 1][column + 1] else 0;
            table[row][column] = table[row - 1][0] * upper_next - table[row - 2][0] * lower_next;
            all_zero = all_zero and table[row][column] == 0;
        }
        if (all_zero or table[row][0] <= 0) return 0;
    }
    return 1;
}
