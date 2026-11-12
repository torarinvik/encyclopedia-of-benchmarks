const MAX_N: i64 = 1_000_000_000_000_000_000;
const MAX_T: usize = 8;
const MAX_K: i64 = 8;
const WIDTH: usize = 9;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn stirlingValue(n: i64, k: usize, modulus: i64) i64 {
    const dimension = k + 1;
    var matrix: [WIDTH * WIDTH]i64 = @splat(0);
    var squared: [WIDTH * WIDTH]i64 = @splat(0);
    var vector: [WIDTH]i64 = @splat(0);
    var next_vector: [WIDTH]i64 = @splat(0);
    for (0..dimension) |index| {
        matrix[index * WIDTH + index] = @rem(@as(i64, @intCast(index)), modulus);
        if (index > 0) matrix[index * WIDTH + index - 1] = 1;
    }
    vector[0] = 1;

    var exponent = n;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) {
            for (0..dimension) |row| {
                var total: i64 = 0;
                for (0..dimension) |column| {
                    total = @rem(total + matrix[row * WIDTH + column] * vector[column], modulus);
                }
                next_vector[row] = total;
            }
            for (0..dimension) |row| vector[row] = next_vector[row];
        }
        exponent = @divTrunc(exponent, 2);
        if (exponent > 0) {
            for (0..dimension) |row| {
                for (0..dimension) |column| {
                    var total: i64 = 0;
                    for (0..dimension) |inner| {
                        total = @rem(total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column], modulus);
                    }
                    squared[row * WIDTH + column] = total;
                }
            }
            for (0..dimension) |row| {
                for (0..dimension) |column| {
                    matrix[row * WIDTH + column] = squared[row * WIDTH + column];
                    squared[row * WIDTH + column] = 0;
                }
            }
        }
    }
    return vector[k];
}

export fn stirling_number_of_the_second_kind_small_p_large_n(
    input_opt: ?[*]const i64,
    length: usize,
) i64 {
    if (input_opt == null or length < 4 or length > 2 + 2 * MAX_T) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    const modulus = input[1];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_T))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count or modulus < 11 or modulus > 97 or !isPrime(modulus)) return -1;

    var result: i64 = 0;
    for (0..count) |case_index| {
        const n = input[2 + 2 * case_index];
        const k_value = input[3 + 2 * case_index];
        if (n < 0 or n > MAX_N or k_value < 0 or k_value > MAX_K or k_value > n) return -1;
        const k: usize = @intCast(k_value);
        const value = stirlingValue(n, k, modulus);
        const next: i64 = @intCast(case_index + 1);
        result = @rem(result + next * next * value, modulus);
    }
    return result;
}
