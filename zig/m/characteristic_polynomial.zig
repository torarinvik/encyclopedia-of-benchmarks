const modulus: i64 = 998244353;
const max_n: usize = 8;
const max_input_values: usize = 1 + max_n * max_n + 1;

fn normalize(value: i64) i64 {
    const remainder = @mod(value, modulus);
    return if (remainder < 0) remainder + modulus else remainder;
}

fn multiply(left: i64, right: i64) i64 {
    return @mod(left * right, modulus);
}

fn power(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn characteristic_polynomial(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > 8) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var matrix: [max_n * max_n]i64 = @splat(0);
    for (0..n) |row| {
        for (0..n) |column| {
            const value = input[1 + row * n + column];
            if (value < 0 or value >= modulus) return -1;
            matrix[row * max_n + column] = value;
        }
    }

    for (0..n) |column| {
        if (column + 2 >= n) break;
        var pivot = column + 1;
        while (pivot < n and matrix[pivot * max_n + column] == 0) : (pivot += 1) {}
        if (pivot == n) continue;
        if (pivot != column + 1) {
            for (0..n) |k| {
                const temporary = matrix[(column + 1) * max_n + k];
                matrix[(column + 1) * max_n + k] = matrix[pivot * max_n + k];
                matrix[pivot * max_n + k] = temporary;
            }
            for (0..n) |row| {
                const temporary = matrix[row * max_n + column + 1];
                matrix[row * max_n + column + 1] = matrix[row * max_n + pivot];
                matrix[row * max_n + pivot] = temporary;
            }
        }
        const inverse = power(matrix[(column + 1) * max_n + column], modulus - 2);
        for (column + 2..n) |row| {
            if (matrix[row * max_n + column] == 0) continue;
            const factor = multiply(matrix[row * max_n + column], inverse);
            for (0..n) |k| {
                matrix[row * max_n + k] = normalize(
                    matrix[row * max_n + k] - multiply(factor, matrix[(column + 1) * max_n + k]));
            }
            for (0..n) |k| {
                matrix[k * max_n + column + 1] = normalize(
                    matrix[k * max_n + column + 1] + multiply(factor, matrix[k * max_n + row]));
            }
        }
    }

    var coefficients: [(max_n + 1) * (max_n + 1)]i64 = @splat(0);
    coefficients[0] = 1;
    for (1..n + 1) |size| {
        for (0..size + 1) |degree| {
            var value: i64 = 0;
            if (degree > 0) value = coefficients[(size - 1) * (max_n + 1) + degree - 1];
            if (degree < size) {
                value -= multiply(matrix[(size - 1) * max_n + size - 1],
                    coefficients[(size - 1) * (max_n + 1) + degree]);
            }
            coefficients[size * (max_n + 1) + degree] = normalize(value);
        }
        var subdiagonal_product: i64 = 1;
        var start: isize = @as(isize, @intCast(size)) - 2;
        while (start >= 0) : (start -= 1) {
            const index: usize = @intCast(start);
            subdiagonal_product = multiply(
                subdiagonal_product, matrix[(index + 1) * max_n + index]);
            const term = multiply(subdiagonal_product, matrix[index * max_n + size - 1]);
            for (0..index + 1) |degree| {
                coefficients[size * (max_n + 1) + degree] = normalize(
                    coefficients[size * (max_n + 1) + degree] -
                    multiply(term, coefficients[index * (max_n + 1) + degree]));
            }
        }
    }

    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..n + 1) |degree|
        storeI64Le(output + 8 * degree, coefficients[n * (max_n + 1) + degree]);
    return @intCast(output_bytes);
}
