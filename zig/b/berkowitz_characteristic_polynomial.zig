const MAX_N: usize = 7;
const MAX_INPUT_WORDS: usize = 52;

fn residue(value: i64, modulus: i64) i64 {
    const result = @rem(value, modulus);
    return if (result < 0) result + modulus else result;
}

fn negativeResidue(value: i64, modulus: i64) i64 {
    return if (value == 0) 0 else modulus - value;
}

fn storeI64Le(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> (byte * 8));
}

export fn berkowitz_characteristic_polynomial(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    const modulus = input[1];
    if (n64 < 1 or n64 > MAX_N or modulus < 2 or modulus > 1_000_000_000) return -1;
    const n: usize = @intCast(n64);
    if (length != 2 + n * n) return -1;

    var matrix: [MAX_N * MAX_N]i64 = @splat(0);
    for (0..n * n) |i| {
        const entry = input[i + 2];
        if (entry < -1_000_000 or entry > 1_000_000) return -1;
        matrix[i] = residue(entry, modulus);
    }
    const output_bytes = (n + 1) * 8;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?;

    var coefficients: [MAX_N + 1]i64 = @splat(0);
    var current: [MAX_N + 1]i64 = @splat(0);
    var toeplitz: [MAX_N + 1]i64 = @splat(0);
    var vector: [MAX_N]i64 = @splat(0);
    var next_vector: [MAX_N]i64 = @splat(0);
    coefficients[0] = 1;
    for (1..n + 1) |size| {
        const start = n - size;
        const block = size - 1;
        @memset(&toeplitz, 0);
        toeplitz[0] = 1;
        toeplitz[1] = negativeResidue(matrix[start * n + start], modulus);
        for (0..block) |row| vector[row] = matrix[(start + 1 + row) * n + start];
        for (0..block) |power| {
            var dot: i64 = 0;
            for (0..block) |col|
                dot = @rem(dot + matrix[start * n + start + 1 + col] * vector[col], modulus);
            toeplitz[power + 2] = negativeResidue(dot, modulus);
            for (0..block) |row| {
                var value: i64 = 0;
                for (0..block) |col|
                    value = @rem(value + matrix[(start + 1 + row) * n + start + 1 + col]
                        * vector[col], modulus);
                next_vector[row] = value;
            }
            for (0..block) |row| vector[row] = next_vector[row];
        }
        for (0..size + 1) |i| {
            var value: i64 = 0;
            const last_child = if (i < size - 1) i else size - 1;
            for (0..last_child + 1) |j|
                value = @rem(value + toeplitz[i - j] * coefficients[j], modulus);
            current[i] = value;
        }
        for (0..size + 1) |i| coefficients[i] = current[i];
    }
    for (0..n + 1) |i| storeI64Le(output, i, coefficients[i]);
    return @intCast(output_bytes);
}
