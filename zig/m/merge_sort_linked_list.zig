const std = @import("std");
const MAX_ITEMS: usize = 128;

fn mergeNodes(values: *const [MAX_ITEMS]i32, next: *[MAX_ITEMS]i32, left: i32, right: i32) i32 {
    if (left < 0) return right;
    if (right < 0) return left;
    const left_index: usize = @intCast(left);
    const right_index: usize = @intCast(right);
    if (values[left_index] <= values[right_index]) {
        const following = next[left_index];
        next[left_index] = mergeNodes(values, next, following, right);
        return left;
    }
    const following = next[right_index];
    next[right_index] = mergeNodes(values, next, left, following);
    return right;
}

fn mergeSortNodes(values: *const [MAX_ITEMS]i32, next: *[MAX_ITEMS]i32, head: i32) i32 {
    if (head < 0 or next[@intCast(head)] < 0) return head;
    var slow = head;
    var fast = next[@intCast(head)];
    while (fast >= 0 and next[@intCast(fast)] >= 0) {
        slow = next[@intCast(slow)];
        fast = next[@intCast(next[@intCast(fast)])];
    }
    const right_head = next[@intCast(slow)];
    next[@intCast(slow)] = -1;
    const left = mergeSortNodes(values, next, head);
    const right = mergeSortNodes(values, next, right_head);
    return mergeNodes(values, next, left, right);
}

fn putI32LE(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @as(u5, @intCast(8 * byte)));
}

export fn merge_sort_linked_list(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 1 + MAX_ITEMS) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_ITEMS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + count) return -1;
    var values = [_]i32{0} ** MAX_ITEMS;
    var next = [_]i32{-1} ** MAX_ITEMS;
    for (0..count) |i| {
        if (input[1 + i] < std.math.minInt(i32) or input[1 + i] > std.math.maxInt(i32)) return -1;
        values[i] = @intCast(input[1 + i]);
        for (0..i) |j| if (values[j] == values[i]) return -1;
        next[i] = if (i + 1 < count) @intCast(i + 1) else -1;
    }
    const head = mergeSortNodes(&values, &next, if (count == 0) -1 else 0);
    const required = 4 * count;
    const output = output_opt orelse return -2;
    if (output_capacity < required) return -2;
    var node = head;
    for (0..count) |i| {
        putI32LE(output, i * 4, values[@intCast(node)]);
        node = next[@intCast(node)];
    }
    return @intCast(required);
}
