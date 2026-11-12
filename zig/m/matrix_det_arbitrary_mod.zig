const max_n: usize = 8;
const max_input_values: usize = 2 + max_n * max_n + 1;
const max_modulus: i64 = 1_000_000_000;

fn normalize(value: i64, modulus: i64) i64 {
    return @mod(value, modulus);
}

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn matrix_det_arbitrary_mod(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const modulus = input[1];
    if (n_value < 0 or n_value > 8 or modulus < 2 or modulus > max_modulus) return -1;
    const n: usize = @intCast(n_value);
    if (length != 2 + n * n) return -1;

    var matrix: [max_n * max_n]i64 = @splat(0);
    for (0..n) |row| {
        for (0..n) |column| {
            const value = input[2 + row * n + column];
            if (value < 0 or value >= modulus) return -1;
            matrix[row * n + column] = value;
        }
    }

    var determinant: i64 = 1;
    var sign = false;
    for (0..n) |column| {
        var pivot = column;
        while (pivot < n and matrix[pivot * n + column] == 0) : (pivot += 1) {}
        if (pivot == n) {
            determinant = 0;
            break;
        }
        if (pivot != column) {
            for (0..n) |k| {
                const temporary = matrix[column * n + k];
                matrix[column * n + k] = matrix[pivot * n + k];
                matrix[pivot * n + k] = temporary;
            }
            sign = !sign;
        }
        for (column + 1..n) |row| {
            var left = matrix[column * n + column];
            var right = matrix[row * n + column];
            if (right == 0) continue;
            var a0: i64 = 1;
            var a1: i64 = 0;
            var b0: i64 = 0;
            var b1: i64 = 1;
            while (left != 0 and right != 0) {
                if (left < right) {
                    const quotient = right / left;
                    right -= quotient * left;
                    b0 = normalize(b0 - a0 * quotient, modulus);
                    b1 = normalize(b1 - a1 * quotient, modulus);
                } else {
                    const quotient = left / right;
                    left -= quotient * right;
                    a0 = normalize(a0 - b0 * quotient, modulus);
                    a1 = normalize(a1 - b1 * quotient, modulus);
                }
            }
            for (column..n) |k| {
                const old_top = matrix[column * n + k];
                const old_bottom = matrix[row * n + k];
                matrix[column * n + k] = normalize(old_top * a0 + old_bottom * a1, modulus);
                matrix[row * n + k] = normalize(old_top * b0 + old_bottom * b1, modulus);
            }
            if (left == 0) {
                for (0..n) |k| {
                    const temporary = matrix[column * n + k];
                    matrix[column * n + k] = matrix[row * n + k];
                    matrix[row * n + k] = temporary;
                }
                sign = !sign;
            }
        }
        determinant = @mod(determinant * matrix[column * n + column], modulus);
        if (determinant == 0) break;
    }
    if (sign and determinant != 0) determinant = modulus - determinant;
    if (output_opt == null or capacity < 8) return -2;
    storeI64Le(output_opt.?, determinant);
    return 8;
}
