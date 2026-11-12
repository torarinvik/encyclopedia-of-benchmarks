const modulus: i64 = 998244353;
const max_order: usize = 8;
const max_terms: usize = 2 * max_order;
const max_input_values: usize = 1 + max_terms + 1;

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

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn inferRecurrence(sequence: *const [max_terms]i64, term_count: usize,
    coefficients: *[max_terms + 1]i64) usize {
    var current: [max_terms + 1]i64 = @splat(0);
    var previous: [max_terms + 1]i64 = @splat(0);
    var old: [max_terms + 1]i64 = @splat(0);
    var current_length: usize = 0;
    var previous_length: usize = 0;
    var last_index: isize = -1;
    var last_discrepancy: i64 = 0;

    for (0..term_count) |index| {
        var predicted: i64 = 0;
        const limit = @min(current_length, index);
        for (0..limit) |lag| {
            predicted = normalize(predicted + multiply(sequence.*[index - lag - 1], current[lag]));
        }
        const discrepancy = normalize(sequence.*[index] - predicted);
        if (discrepancy == 0) continue;

        if (last_index < 0) {
            last_index = @intCast(index);
            last_discrepancy = discrepancy;
            current_length = index + 1;
            for (0..current_length) |lag| current[lag] = 0;
            continue;
        }

        for (0..current_length) |lag| old[lag] = current[lag];
        const old_length = current_length;
        const shift: usize = @intCast(@as(isize, @intCast(index)) - last_index);
        const scale = multiply(discrepancy, power(last_discrepancy, modulus - 2));
        const needed_length = previous_length + shift;
        if (current_length < needed_length) {
            for (current_length..needed_length) |lag| current[lag] = 0;
            current_length = needed_length;
        }
        current[shift - 1] = normalize(current[shift - 1] + scale);
        for (0..previous_length) |lag| {
            current[shift + lag] = normalize(current[shift + lag] - multiply(scale, previous[lag]));
        }

        if (@as(isize, @intCast(old_length)) - @as(isize, @intCast(index))
            < @as(isize, @intCast(previous_length)) - last_index)
        {
            for (0..old_length) |lag| previous[lag] = old[lag];
            previous_length = old_length;
            last_index = @intCast(index);
            last_discrepancy = discrepancy;
        }
    }

    for (0..current_length) |lag| coefficients.*[lag] = current[lag];
    return current_length;
}

export fn berlekamp_massey(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const bound_value = input[0];
    if (bound_value < 1 or bound_value > 8) return -1;
    const bound: usize = @intCast(bound_value);
    const term_count = 2 * bound;
    if (length != 1 + term_count) return -1;

    var sequence: [max_terms]i64 = @splat(0);
    for (0..term_count) |index| {
        const value = input[1 + index];
        if (value < 0 or value >= modulus) return -1;
        sequence[index] = value;
    }
    var coefficients: [max_terms + 1]i64 = @splat(0);
    const order = inferRecurrence(&sequence, term_count, &coefficients);
    if (order > bound) return -1;

    const output_bytes = 8 * (order + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(order));
    for (0..order) |lag| storeI64Le(output, 8 * (lag + 1), coefficients[lag]);
    return @intCast(output_bytes);
}
