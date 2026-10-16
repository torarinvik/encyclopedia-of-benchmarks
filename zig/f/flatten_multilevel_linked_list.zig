const MAX_LISTS: usize = 8;
const MAX_CHAIN_LENGTH: usize = 8;
const MAX_TOTAL_VALUES: usize = MAX_LISTS * MAX_CHAIN_LENGTH;
const MAX_INPUT_LENGTH: usize = 1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH);

fn mergeRecursive(left: [*]const i64, left_length: usize, left_index: usize,
    right: [*]const i64, right_length: usize, right_index: usize,
    output: [*]i64, output_index: usize) usize {
    if (left_index == left_length) {
        const remaining = right_length - right_index;
        for (0..remaining) |i| output[output_index + i] = right[right_index + i];
        return output_index + remaining;
    }
    if (right_index == right_length) {
        const remaining = left_length - left_index;
        for (0..remaining) |i| output[output_index + i] = left[left_index + i];
        return output_index + remaining;
    }
    if (left[left_index] < right[right_index]) {
        output[output_index] = left[left_index];
        return mergeRecursive(left, left_length, left_index + 1, right, right_length,
            right_index, output, output_index + 1);
    }
    output[output_index] = right[right_index];
    return mergeRecursive(left, left_length, left_index, right, right_length,
        right_index + 1, output, output_index + 1);
}

fn flattenSuffix(lists: [*]const i64, lengths: [*]const usize, count: usize,
    index: usize, output: [*]i64) usize {
    const row = index * MAX_CHAIN_LENGTH;
    if (index + 1 == count) {
        for (0..lengths[index]) |i| output[i] = lists[row + i];
        return lengths[index];
    }
    var suffix: [MAX_TOTAL_VALUES]i64 = undefined;
    const suffix_length = flattenSuffix(lists, lengths, count, index + 1, &suffix);
    return mergeRecursive(&lists[row], lengths[index], 0, &suffix, suffix_length, 0, output, 0);
}

fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

export fn flatten_multilevel_linked_list(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > MAX_LISTS) return -1;
    const count: usize = @intCast(values[0]);
    if (count == 0) return if (length == 1) 0 else -1;

    var lists: [MAX_LISTS * MAX_CHAIN_LENGTH]i64 = undefined;
    var lengths: [MAX_LISTS]usize = undefined;
    var total: usize = 0;
    var cursor: usize = 1;
    for (0..count) |list| {
        if (cursor >= length or values[cursor] < 1 or values[cursor] > MAX_CHAIN_LENGTH) return -1;
        const chain_length: usize = @intCast(values[cursor]);
        cursor += 1;
        if (chain_length > length - cursor) return -1;
        lengths[list] = chain_length;
        const row = list * MAX_CHAIN_LENGTH;
        for (0..chain_length) |item| {
            const value = values[cursor];
            cursor += 1;
            if (value < -1000 or value > 1000 or
                (item > 0 and value < lists[row + item - 1])) return -1;
            lists[row + item] = value;
        }
        total += chain_length;
    }
    if (cursor != length) return -1;
    const required = total * 8;
    if (output == null or capacity < required) return -2;

    var flattened: [MAX_TOTAL_VALUES]i64 = undefined;
    _ = flattenSuffix(&lists, &lengths, count, 0, &flattened);
    for (0..total) |i| storeI64(output, 8 * i, flattened[i]);
    return @intCast(total);
}
