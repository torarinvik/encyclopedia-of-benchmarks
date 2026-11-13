const MAX_DIMENSION: usize = 8;
const MAX_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn bareiss_determinant(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > MAX_DIMENSION) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return INVALID_RESULT;

    var matrix = [_]i64{0} ** (MAX_DIMENSION * MAX_DIMENSION);
    for (0..n * n) |index| {
        const value = input[1 + index];
        if (value < -4 or value > 4) return INVALID_RESULT;
        matrix[index] = value;
    }

    var sign: i64 = 1;
    var previous_pivot: i64 = 1;
    for (0..n - 1) |k| {
        if (matrix[k * n + k] == 0) {
            var replacement = k + 1;
            while (replacement < n and matrix[replacement * n + k] == 0) : (replacement += 1) {}
            if (replacement == n) return 0;
            for (0..n) |column| {
                const temporary = matrix[k * n + column];
                matrix[k * n + column] = matrix[replacement * n + column];
                matrix[replacement * n + column] = temporary;
            }
            sign = -sign;
        }

        const pivot = matrix[k * n + k];
        for (k + 1..n) |row| {
            for (k + 1..n) |column| {
                const numerator = matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column];
                matrix[row * n + column] = @divTrunc(numerator, previous_pivot);
            }
            matrix[row * n + k] = 0;
        }
        previous_pivot = pivot;
    }
    return sign * matrix[(n - 1) * n + n - 1];
}
