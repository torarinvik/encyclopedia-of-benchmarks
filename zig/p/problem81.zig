const MAX_DIMENSION: usize = 80;
const MAX_CELL_VALUE: i64 = 9999;

pub export fn problem81(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -1;
    const dimension_value = input[0];
    if (dimension_value < 1 or dimension_value > MAX_DIMENSION) return -1;
    const dimension: usize = @intCast(dimension_value);
    if (length != 1 + dimension * dimension) return -1;
    for (1..length) |index| if (input[index] < 0 or input[index] > MAX_CELL_VALUE) return -1;

    var costs: [MAX_DIMENSION]i64 = undefined;
    costs[0] = input[1];
    for (1..dimension) |column| {
        costs[column] = costs[column - 1] + input[1 + column];
    }
    for (1..dimension) |row| {
        const row_offset = 1 + row * dimension;
        costs[0] += input[row_offset];
        for (1..dimension) |column| {
            const above = costs[column];
            const left = costs[column - 1];
            costs[column] = @min(above, left) + input[row_offset + column];
        }
    }
    return costs[dimension - 1];
}
