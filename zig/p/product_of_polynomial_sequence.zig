const MODULUS: i64 = 998_244_353;
const MAX_FACTORS: usize = 6;
const MAX_COEFFICIENTS: usize = 25;
const MAX_INPUT: usize = 38;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn product_of_polynomial_sequence(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_FACTORS))) return -1;
    const count: usize = @intCast(input[0]);
    var polynomials: [MAX_FACTORS * MAX_COEFFICIENTS]i64 = @splat(0);
    var lengths: [MAX_FACTORS]usize = @splat(0);
    var cursor: usize = 1;
    var degree_sum: usize = 0;
    for (0..count) |p| {
        if (cursor >= length or input[cursor] < 0 or input[cursor] > 4) return -1;
        const degree: usize = @intCast(input[cursor]);
        cursor += 1;
        if (cursor + degree + 1 > length) return -1;
        for (0..(degree + 1)) |i| {
            const coefficient = input[cursor + i];
            if (coefficient < 0 or coefficient >= MODULUS) return -1;
            polynomials[p * MAX_COEFFICIENTS + i] = coefficient;
        }
        if (polynomials[p * MAX_COEFFICIENTS + degree] == 0) return -1;
        lengths[p] = degree + 1;
        degree_sum += degree;
        cursor += degree + 1;
    }
    if (cursor != length) return -1;

    const result_length = degree_sum + 1;
    const bytes = 8 * result_length;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    if (count == 0) {
        storeLe(output, 0, 1);
        return 8;
    }

    var scratch: [MAX_COEFFICIENTS]i64 = @splat(0);
    var active = count;
    while (active > 1) {
        var next_count: usize = 0;
        var i: usize = 0;
        while (i < active) : (i += 2) {
            const destination = next_count * MAX_COEFFICIENTS;
            if (i + 1 == active) {
                const source = i * MAX_COEFFICIENTS;
                for (0..lengths[i]) |j| polynomials[destination + j] = polynomials[source + j];
                lengths[next_count] = lengths[i];
            } else {
                const left_start = i * MAX_COEFFICIENTS;
                const right_start = (i + 1) * MAX_COEFFICIENTS;
                const product_length = lengths[i] + lengths[i + 1] - 1;
                for (0..product_length) |j| scratch[j] = 0;
                for (0..lengths[i]) |a| {
                    for (0..lengths[i + 1]) |b| {
                        const slot = a + b;
                        scratch[slot] = @rem(scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b], MODULUS);
                    }
                }
                for (0..product_length) |j| polynomials[destination + j] = scratch[j];
                lengths[next_count] = product_length;
            }
            next_count += 1;
        }
        active = next_count;
    }
    for (0..result_length) |i| storeLe(output, 8 * i, polynomials[i]);
    return @intCast(bytes);
}
