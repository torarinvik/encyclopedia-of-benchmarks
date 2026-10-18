const std = @import("std");

const max_ops = 64;
const max_input = 130;
const max_output = 256;

export fn priority_queue(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > max_input) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > max_ops) return -1;
    const op_count: usize = @intCast(values[0]);
    var heap = [_]i32{0} ** max_ops;
    var seen = [_]i32{0} ** max_ops;
    var staged = [_]u8{0} ** max_output;
    var heap_size: usize = 0;
    var seen_count: usize = 0;
    var offset: usize = 1;
    var output_size: usize = 0;
    for (0..op_count) |_| {
        if (offset >= input_length) return -1;
        const op = values[offset];
        offset += 1;
        if (op == 0) {
            if (offset >= input_length) return -1;
            const raw = values[offset];
            offset += 1;
            if (raw < std.math.minInt(i32) or raw > std.math.maxInt(i32)) return -1;
            const value: i32 = @intCast(raw);
            for (seen[0..seen_count]) |prior| if (prior == value) return -1;
            seen[seen_count] = value;
            seen_count += 1;
            var i = heap_size;
            heap_size += 1;
            heap[i] = value;
            while (i > 0) {
                const parent = (i - 1) / 2;
                if (heap[parent] <= heap[i]) break;
                const temp = heap[parent]; heap[parent] = heap[i]; heap[i] = temp;
                i = parent;
            }
        } else if (op == 1 or op == 2) {
            if (heap_size == 0) return -1;
            const bytes = @as(u32, @bitCast(heap[0]));
            staged[output_size] = @truncate(bytes); output_size += 1;
            staged[output_size] = @truncate(bytes >> 8); output_size += 1;
            staged[output_size] = @truncate(bytes >> 16); output_size += 1;
            staged[output_size] = @truncate(bytes >> 24); output_size += 1;
            if (op == 2) {
                heap_size -= 1;
                heap[0] = heap[heap_size];
                var i: usize = 0;
                while (i < heap_size) {
                    var child = 2 * i + 1;
                    if (child >= heap_size) break;
                    if (child + 1 < heap_size and heap[child + 1] < heap[child]) child += 1;
                    if (heap[i] <= heap[child]) break;
                    const temp = heap[i]; heap[i] = heap[child]; heap[child] = temp;
                    i = child;
                }
            }
        } else return -1;
    }
    if (offset != input_length) return -1;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
