const MAX_DIMENSION: usize = 6;
const MAX_INPUT_LENGTH: usize = 1 + MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn determinantRecursive(matrix: [*c]const i64, dimension: usize) i64 {
    if (dimension == 1) return matrix[0];
    var result: i64 = 0;
    var minor: [25]i64 = @splat(0);
    for (0..dimension) |column| {
        var minor_index: usize = 0;
        for (1..dimension) |row| {
            for (0..dimension) |source_column| {
                if (source_column == column) continue;
                minor[minor_index] = matrix[row * dimension + source_column];
                minor_index += 1;
            }
        }
        const term = matrix[column] * determinantRecursive(&minor[0], dimension - 1);
        result += if (column % 2 == 0) term else -term;
    }
    return result;
}

pub export fn determinant(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const dimension_value = input[0];
    if (dimension_value < 1 or dimension_value > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const dimension: usize = @intCast(dimension_value);
    if (length != 1 + dimension * dimension) return INVALID_RESULT;
    for (0..dimension * dimension) |index| {
        const value = input[1 + index];
        if (value < -9 or value > 9) return INVALID_RESULT;
    }
    return determinantRecursive(&input[1], dimension);
}
