const max_dimension: usize = 64;
const max_input_values: usize = 3 + 2 * max_dimension * max_dimension;
const max_output_values: usize = max_dimension * max_dimension;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn matrix_product_mod_2(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    const k_value = input[2];
    if (n_value < 1 or n_value > 64 or m_value < 1 or m_value > 64 or
        k_value < 1 or k_value > 64) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const k: usize = @intCast(k_value);
    const a_length = n * m;
    const b_length = m * k;
    if (length != 3 + a_length + b_length) return -1;

    var packed_b: [max_dimension]u64 = @splat(0);
    const b_start = 3 + a_length;
    for (0..m) |inner| {
        for (0..k) |column| {
            const bit = input[b_start + inner * k + column];
            if (bit != 0 and bit != 1) return -1;
            packed_b[inner] |= @as(u64, @intCast(bit)) << @intCast(column);
        }
    }

    var staged: [max_output_values]i64 = @splat(0);
    for (0..n) |row| {
        var accumulator: u64 = 0;
        for (0..m) |inner| {
            const bit = input[3 + row * m + inner];
            if (bit != 0 and bit != 1) return -1;
            if (bit == 1) accumulator ^= packed_b[inner];
        }
        for (0..k) |column|
            staged[row * k + column] = @intCast((accumulator >> @intCast(column)) & 1);
    }

    const required = 8 * n * k;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..n * k) |index| storeI64Le(output, 8 * index, staged[index]);
    return @intCast(required);
}
