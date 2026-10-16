/// Enumerate positive value lists in include-first source order.
const MAX_ITEMS: usize = 11;
const MAX_TARGET: i64 = 256;
const MAX_ITEM: i64 = 64;

fn writeI64Le(output: [*]u8, position: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        output[position.*] = @truncate(bits >> @intCast(8 * byte_index));
        position.* += 1;
    }
}

fn enumerate(items: []const i64, index: usize, target: i64, total: i64,
             chosen: *[MAX_ITEMS]i64, chosen_count: usize,
             output: ?[*]u8, position: *usize, emit: bool) usize {
    if (total == target) {
        if (emit) {
            const out = output.?;
            writeI64Le(out, position, @intCast(chosen_count));
            for (chosen[0..chosen_count]) |value| writeI64Le(out, position, value);
        }
        return chosen_count + 1;
    }
    if (index == items.len or total > target) return 0;
    chosen[chosen_count] = items[index];
    const include_slots = enumerate(items, index + 1, target, total + items[index],
        chosen, chosen_count + 1, output, position, emit);
    const exclude_slots = enumerate(items, index + 1, target, total,
        chosen, chosen_count, output, position, emit);
    return include_slots + exclude_slots;
}

export fn subset_sum_values_enumeration(input: ?[*]const i64, length: usize,
        output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_ITEMS + 1) return -1;
    const values = input.?[0..length];
    const target = values[0];
    if (target < 0 or target > MAX_TARGET) return -1;
    for (values[1..]) |item| {
        if (item < 1 or item > MAX_ITEM) return -1;
    }
    var chosen: [MAX_ITEMS]i64 = @splat(0);
    var dummy_position: usize = 0;
    const slots = enumerate(values[1..], 0, target, 0, &chosen, 0,
        output, &dummy_position, false);
    const required = slots * 8;
    if (required == 0) return 0;
    if (output == null or output_capacity < required) return -2;
    var position: usize = 0;
    _ = enumerate(values[1..], 0, target, 0, &chosen, 0,
        output, &position, true);
    return @intCast(position);
}
