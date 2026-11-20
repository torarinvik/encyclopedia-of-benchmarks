const MAX_VALUES: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_FUNCTION_VALUE: i64 = 1_000_000;

fn transform(values: *[MAX_VALUES]i64, bit_count: usize, state_count: usize) i64 {
    for (0..bit_count) |bit_index| {
        const bit_mask = @as(usize, 1) << @intCast(bit_index);
        for (0..state_count) |mask| {
            if ((mask & bit_mask) != 0) values[mask] += values[mask ^ bit_mask];
        }
    }
    var checksum: i64 = 0;
    for (0..state_count) |mask| {
        checksum += @as(i64, @intCast(mask + 1)) * values[mask];
    }
    return checksum;
}

export fn sum_over_subsets_zeta_transform(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const bit_count_value = input[0];
    if (bit_count_value < 0 or bit_count_value > 6) return -1;
    const bit_count: usize = @intCast(bit_count_value);
    const state_count: usize = @as(usize, 1) << @intCast(bit_count);
    if (length != state_count + 1) return -1;

    var values: [MAX_VALUES]i64 = @splat(0);
    for (0..state_count) |mask| {
        const value = input[mask + 1];
        if (value < 0 or value > MAX_FUNCTION_VALUE) return -1;
        values[mask] = value;
    }
    return transform(&values, bit_count, state_count);
}
