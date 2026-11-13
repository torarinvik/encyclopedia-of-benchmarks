const modulus: i64 = 998244353;
const max_n: usize = 8;
const max_dimension: usize = 16;
const max_parseable: usize = 258;

fn normalize(value: i64) i64 {
    const remainder = @mod(value, modulus);
    return if (remainder < 0) remainder + modulus else remainder;
}

fn multiply(left: i64, right: i64) i64 { return @mod(left * right, modulus); }

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

export fn pfaffian_of_matrix(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 5 or length > max_parseable) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const dimension: usize = @intCast(2 * input[0]);
    if (length != 1 + dimension * dimension) return -1;

    var matrix: [max_dimension * max_dimension]i64 = @splat(0);
    for (0..dimension) |row| {
        for (0..dimension) |column| {
            const value = input[1 + row * dimension + column];
            if (value < 0 or value >= modulus) return -1;
            matrix[row * max_dimension + column] = value;
        }
    }
    for (0..dimension) |row| {
        if (matrix[row * max_dimension + row] != 0) return -1;
        for (row + 1..dimension) |column| {
            if (@mod(matrix[row * max_dimension + column]
                    + matrix[column * max_dimension + row], modulus) != 0) return -1;
        }
    }

    var result: i64 = 1;
    var pivot_index: usize = 0;
    while (pivot_index < dimension) : (pivot_index += 2) {
        var partner = pivot_index + 1;
        while (partner < dimension and matrix[pivot_index * max_dimension + partner] == 0) : (partner += 1) {}
        if (partner == dimension) return 0;
        if (partner != pivot_index + 1) {
            const swapped = pivot_index + 1;
            for (0..dimension) |k| {
                const temporary = matrix[swapped * max_dimension + k];
                matrix[swapped * max_dimension + k] = matrix[partner * max_dimension + k];
                matrix[partner * max_dimension + k] = temporary;
            }
            for (0..dimension) |k| {
                const temporary = matrix[k * max_dimension + swapped];
                matrix[k * max_dimension + swapped] = matrix[k * max_dimension + partner];
                matrix[k * max_dimension + partner] = temporary;
            }
            if (result != 0) result = modulus - result;
        }

        const first = pivot_index * max_dimension;
        const second = (pivot_index + 1) * max_dimension;
        const pivot = matrix[first + pivot_index + 1];
        result = multiply(result, pivot);
        const inverse = power(pivot, modulus - 2);
        for (pivot_index + 2..dimension) |row| {
            for (row + 1..dimension) |column| {
                const cross = normalize(multiply(matrix[first + row], matrix[second + column])
                    - multiply(matrix[first + column], matrix[second + row]));
                const value = normalize(matrix[row * max_dimension + column]
                    - multiply(cross, inverse));
                matrix[row * max_dimension + column] = value;
                matrix[column * max_dimension + row] = if (value == 0) 0 else modulus - value;
            }
        }
    }
    return result;
}
