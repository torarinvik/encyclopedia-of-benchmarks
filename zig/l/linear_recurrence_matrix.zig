const MODULUS: i64 = 1_000_000_007;
const MAX_INPUT_LENGTH: usize = 24;

fn multiplyMatrix(left: [16]i64, right: [16]i64, dimension: usize) [16]i64 {
    var output: [16]i64 = @splat(0);
    for (0..dimension) |row| {
        for (0..dimension) |column| {
            var value: i64 = 0;
            for (0..dimension) |inner| {
                value = @rem(value + @rem(left[row * dimension + inner], MODULUS) *
                    @rem(right[inner * dimension + column], MODULUS), MODULUS);
            }
            output[row * dimension + column] = value;
        }
    }
    return output;
}

fn matrixPower(matrix: [16]i64, dimension: usize, initial_power: i64) [16]i64 {
    var zero = true;
    for (0..dimension * dimension) |index| {
        if (matrix[index] != 0) zero = false;
    }
    if (zero) return @splat(0);
    var result: [16]i64 = @splat(0);
    var base = matrix;
    for (0..dimension) |index| result[index * dimension + index] = 1;
    var power = initial_power;
    while (power > 0) {
        if ((power & 1) != 0) result = multiplyMatrix(result, base, dimension);
        power = @divTrunc(power, 2);
        base = multiplyMatrix(base, base, dimension);
    }
    return result;
}

export fn linear_recurrence_matrix(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const dimension_value = input[0];
    const nth_term = input[1];
    const constant_or_sum_included = input[2];
    if (dimension_value < 1 or dimension_value > 4 or nth_term < 0 or nth_term > 1_000_000 or
        (constant_or_sum_included != 0 and constant_or_sum_included != 1)) return -1;
    const dimension: usize = @intCast(dimension_value);
    const matrix_count = dimension * dimension;
    if (length != 3 + matrix_count + dimension or
        (constant_or_sum_included == 1 and nth_term < dimension_value - 1)) return -1;

    var matrix: [16]i64 = @splat(0);
    var base_row: [4]i64 = @splat(0);
    for (0..matrix_count + dimension) |index| {
        const value = input[3 + index];
        if (value < 0 or value >= MODULUS) return -1;
        if (index < matrix_count) matrix[index] = value else base_row[index - matrix_count] = value;
    }
    if (nth_term < dimension_value - constant_or_sum_included)
        return base_row[@intCast(nth_term - constant_or_sum_included)];

    var zero = true;
    for (0..matrix_count) |index| {
        if (matrix[index] != 0) zero = false;
    }
    if (zero) return 0;
    const power = nth_term - dimension_value + 1 + constant_or_sum_included;
    const result = matrixPower(matrix, dimension, power);
    var value: i64 = 0;
    for (0..dimension) |index| {
        value = @rem(value + @rem(base_row[index], MODULUS) *
            @rem(result[index * dimension + dimension - 1], MODULUS), MODULUS);
    }
    return value;
}
