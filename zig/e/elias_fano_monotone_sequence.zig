const MAX_VALUES: usize = 32;
const MAX_HIGH_BITS: usize = 96;
const MAX_INPUT_LENGTH: usize = 35;

export fn elias_fano_monotone_sequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    const upper = input[1];
    if (count_value < 1 or count_value > 32 or upper < 0 or upper > 1_000_000) return -1;
    const count: usize = @intCast(count_value);
    if (count_value > upper + 1 or length != count + 2) return -1;

    var source: [MAX_VALUES]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < 0 or value > upper or (index > 0 and value < source[index - 1])) return -1;
        source[index] = value;
    }

    var low_width: usize = 0;
    var low_power: i64 = 1;
    while (@as(i64, @intCast(count)) * low_power * 2 <= upper + 1) {
        low_power *= 2;
        low_width += 1;
    }
    const low_mask = low_power - 1;
    var low_parts: [MAX_VALUES]i64 = @splat(0);
    var high_bits: [MAX_HIGH_BITS]bool = @splat(false);
    const high_length: usize = @as(usize, @intCast(@divTrunc(upper, low_power))) + count;
    if (high_length > MAX_HIGH_BITS) return -1;
    for (0..count) |index| {
        low_parts[index] = source[index] & low_mask;
        const position: usize = @as(usize, @intCast(@divTrunc(source[index], low_power))) + index;
        if (position >= high_length) return -1;
        high_bits[position] = true;
    }

    var checksum: i64 = 0;
    var item_index: usize = 0;
    for (0..high_length) |position| {
        if (!high_bits[position]) continue;
        if (item_index >= count or position < item_index) return -1;
        const high_part = position - item_index;
        const decoded = (@as(i64, @intCast(high_part)) << @intCast(low_width)) | low_parts[item_index];
        checksum += (@as(i64, @intCast(item_index)) + 1) * decoded;
        item_index += 1;
    }
    if (item_index != count) return -1;
    return checksum;
}
