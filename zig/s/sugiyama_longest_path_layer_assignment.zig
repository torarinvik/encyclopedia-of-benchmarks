const max_n: usize = 32;
const max_m: usize = 128;
const max_input: usize = 258;

fn putI64Le(output: [*]u8, word: usize, value: u64) void {
    for (0..8) |byte| {
        output[word * 8 + byte] = @truncate(value >> @as(u6, @intCast(byte * 8)));
    }
}

export fn sugiyama_longest_path_layer_assignment(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input + 1) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > 32 or m64 < 0 or m64 > 128) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;

    var adjacency: [max_n]u32 = [_]u32{0} ** max_n;
    for (0..m) |edge| {
        const source = input[2 + 2 * edge];
        const target = input[3 + 2 * edge];
        if (source < 0 or source >= n64 or target < 0 or target >= n64) return -1;
        const s: usize = @intCast(source);
        const t: usize = @intCast(target);
        const bit = @as(u32, 1) << @intCast(t);
        if (adjacency[s] & bit != 0) return -1;
        adjacency[s] |= bit;
    }

    var removed: [max_n]bool = [_]bool{false} ** max_n;
    var sink_depth: [max_n]usize = [_]usize{0} ** max_n;
    var remaining = n;
    var depth: usize = 0;
    while (remaining > 0) {
        var sinks: [max_n]bool = [_]bool{false} ** max_n;
        var sink_count: usize = 0;
        for (0..n) |vertex| {
            if (removed[vertex]) continue;
            var has_remaining_successor = false;
            for (0..n) |target| {
                if (!removed[target] and (adjacency[vertex] & (@as(u32, 1) << @intCast(target))) != 0) {
                    has_remaining_successor = true;
                    break;
                }
            }
            if (!has_remaining_successor) { sinks[vertex] = true; sink_count += 1; }
        }
        if (sink_count == 0) return -1;
        for (0..n) |vertex| {
            if (sinks[vertex]) { removed[vertex] = true; sink_depth[vertex] = depth; }
        }
        remaining -= sink_count;
        depth += 1;
    }

    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    putI64Le(output, 0, @intCast(depth));
    for (0..n) |vertex| putI64Le(output, vertex + 1, @intCast(depth - 1 - sink_depth[vertex]));
    return @intCast(output_bytes);
}
