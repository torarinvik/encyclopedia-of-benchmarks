const MAX_NODES: usize = 128;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 12 * MAX_NODES;

const ListNode = struct { value: i32, next: i32, origin: i32, position: i32 };

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn merge_sorted_singly_linked_list(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize,
) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_NODES) return -1;
    const len_a: usize = @intCast(input[0]);
    if (len_a > length - 2) return -1;
    const len_b_pos = 1 + len_a;
    const raw_len_b = input[len_b_pos];
    if (raw_len_b < 0 or raw_len_b > @as(i64, @intCast(MAX_NODES - len_a))) return -1;
    const len_b: usize = @intCast(raw_len_b);
    const total = len_a + len_b;
    if (length != 2 + total) return -1;

    var nodes: [MAX_NODES]ListNode = undefined;
    for (0..len_a) |i| {
        const raw = input[1 + i];
        if (raw < -2147483648 or raw > 2147483647 or (i > 0 and input[i] > raw)) return -1;
        nodes[i] = .{ .value = @intCast(raw), .next = if (i + 1 < len_a) @intCast(i + 1) else -1, .origin = 0, .position = @intCast(i) };
    }
    const b_start = len_b_pos + 1;
    for (0..len_b) |i| {
        const raw = input[b_start + i];
        if (raw < -2147483648 or raw > 2147483647 or (i > 0 and input[b_start + i - 1] > raw)) return -1;
        const node = len_a + i;
        nodes[node] = .{ .value = @intCast(raw), .next = if (i + 1 < len_b) @intCast(node + 1) else -1, .origin = 1, .position = @intCast(i) };
    }

    var head_a: i32 = if (len_a == 0) -1 else 0;
    var head_b: i32 = if (len_b == 0) -1 else @intCast(len_a);
    var merged_head: i32 = -1;
    var tail: i32 = -1;
    while (head_a >= 0 and head_b >= 0) {
        var node: i32 = undefined;
        if (nodes[@intCast(head_a)].value <= nodes[@intCast(head_b)].value) {
            node = head_a;
            head_a = nodes[@intCast(node)].next;
        } else {
            node = head_b;
            head_b = nodes[@intCast(node)].next;
        }
        if (tail < 0) merged_head = node else nodes[@intCast(tail)].next = node;
        tail = node;
    }
    const remainder = if (head_a >= 0) head_a else head_b;
    if (tail < 0) merged_head = remainder else nodes[@intCast(tail)].next = remainder;

    const bytes = 12 * total;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var written: usize = 0;
    var node = merged_head;
    while (node >= 0) {
        const item = nodes[@intCast(node)];
        putI32Le(&buffer, written, item.value);
        putI32Le(&buffer, written + 4, item.origin);
        putI32Le(&buffer, written + 8, item.position);
        written += 12;
        node = item.next;
    }
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
