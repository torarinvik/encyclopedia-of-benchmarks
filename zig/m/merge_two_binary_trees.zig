const MAX_TREE_SLOTS: usize = 255;
const MAX_INPUT_LENGTH: usize = 512;
const NULL_SLOT: i64 = -1_000_001;

fn validTree(input: [*]const i64, start: usize, count: usize) bool {
    for (0..count) |index| {
        const value = input[start + index];
        if (value != NULL_SLOT and (value < -100_000 or value > 100_000)) return false;
        if (index > 0 and input[start + (index - 1) / 2] == NULL_SLOT and value != NULL_SLOT) return false;
    }
    return true;
}

export fn merge_two_binary_trees(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > 255) return -1;
    const first_count: usize = @intCast(input[0]);
    const second_count_position = first_count + 1;
    if (second_count_position >= length) return -1;
    if (input[second_count_position] < 0 or input[second_count_position] > 255) return -1;
    const second_count: usize = @intCast(input[second_count_position]);
    const first_start: usize = 1;
    const second_start = second_count_position + 1;
    if (length != second_start + second_count) return -1;
    if (!validTree(input, first_start, first_count) or !validTree(input, second_start, second_count)) return -1;

    const maximum_slots = @max(first_count, second_count);
    var merged: [MAX_TREE_SLOTS]i32 = undefined;
    var node_count: i64 = 0;
    for (0..maximum_slots) |index| {
        const first = if (index < first_count) input[first_start + index] else NULL_SLOT;
        const second = if (index < second_count) input[second_start + index] else NULL_SLOT;
        if (first == NULL_SLOT and second == NULL_SLOT) {
            merged[index] = @intCast(NULL_SLOT);
        } else {
            const first_value: i64 = if (first == NULL_SLOT) 0 else first;
            const second_value: i64 = if (second == NULL_SLOT) 0 else second;
            merged[index] = @intCast(first_value + second_value);
            node_count += 1;
        }
    }
    var output_slots = maximum_slots;
    while (output_slots > 0 and merged[output_slots - 1] == @as(i32, @intCast(NULL_SLOT))) output_slots -= 1;
    const output_bytes = output_slots * 4;
    if (output_capacity < output_bytes) return -2;
    for (0..output_slots) |index| {
        const bits: u32 = @bitCast(merged[index]);
        for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return node_count;
}
