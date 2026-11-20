const MAX_N: usize = 7;
const MAX_Q: usize = 105;
const MAX_NODES: usize = 13;

fn storeWord(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(8 * byte);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn aho_build_rooted_triplet_tree(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 318) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or values[1] < 0) return -1;
    const n: usize = @intCast(values[0]);
    const q_limit = if (n < 3) 0 else n * (n - 1) * (n - 2) / 2;
    if (values[1] > @as(i64, @intCast(q_limit))) return -1;
    const q: usize = @intCast(values[1]);
    if (length != 2 + 3 * q) return -1;

    var triples: [MAX_Q][3]i32 = undefined;
    for (0..q) |i| {
        const a0 = values[2 + 3 * i];
        const b0 = values[3 + 3 * i];
        const c0 = values[4 + 3 * i];
        if (a0 < 0 or a0 >= @as(i64, @intCast(n)) or b0 < 0 or b0 >= @as(i64, @intCast(n)) or c0 < 0 or c0 >= @as(i64, @intCast(n)) or a0 == b0 or a0 == c0 or b0 == c0) return -1;
        var a: i32 = @intCast(a0);
        var b: i32 = @intCast(b0);
        if (a > b) { const t = a; a = b; b = t; }
        for (0..i) |j| {
            if (triples[j][0] == a and triples[j][1] == b and triples[j][2] == @as(i32, @intCast(c0))) return -1;
        }
        triples[i] = .{ a, b, @intCast(c0) };
    }

    var kind: [MAX_NODES]i32 = @splat(0);
    var node_value: [MAX_NODES]i32 = @splat(0);
    var tasks: [MAX_NODES]u8 = undefined;
    tasks[0] = @intCast((@as(usize, 1) << n) - 1);
    var top: usize = 1;
    var node_count: usize = 0;
    var compatible = true;
    while (top > 0) {
        top -= 1;
        const mask = tasks[top];
        if ((mask & (mask - 1)) == 0) {
            var label: usize = 0;
            while ((mask & (@as(u8, 1) << @as(u3, @intCast(label)))) == 0) label += 1;
            kind[node_count] = 1;
            node_value[node_count] = @intCast(label);
            node_count += 1;
            continue;
        }
        var edge: [MAX_N * MAX_N]bool = @splat(false);
        for (triples[0..q]) |t| {
            const needed: u8 = (@as(u8, 1) << @as(u3, @intCast(t[0]))) | (@as(u8, 1) << @as(u3, @intCast(t[1]))) | (@as(u8, 1) << @as(u3, @intCast(t[2])));
            if ((mask & needed) == needed) {
                edge[@as(usize, @intCast(t[0])) * MAX_N + @as(usize, @intCast(t[1]))] = true;
                edge[@as(usize, @intCast(t[1])) * MAX_N + @as(usize, @intCast(t[0]))] = true;
            }
        }
        var seen: [MAX_N]bool = @splat(false);
        var components: [MAX_N]u8 = undefined;
        var component_count: usize = 0;
        for (0..n) |start| {
            const bit: u8 = @as(u8, 1) << @as(u3, @intCast(start));
            if ((mask & bit) == 0 or seen[start]) continue;
            var queue: [MAX_N]usize = undefined;
            var head: usize = 0;
            var tail: usize = 1;
            var component: u8 = 0;
            queue[0] = start;
            seen[start] = true;
            while (head < tail) {
                const current = queue[head];
                head += 1;
                component |= @as(u8, 1) << @as(u3, @intCast(current));
                for (0..n) |other| {
                    const other_bit: u8 = @as(u8, 1) << @as(u3, @intCast(other));
                    if (edge[current * MAX_N + other] and (mask & other_bit) != 0 and !seen[other]) {
                        seen[other] = true;
                        queue[tail] = other;
                        tail += 1;
                    }
                }
            }
            components[component_count] = component;
            component_count += 1;
        }
        if (component_count == 1) { compatible = false; break; }
        node_value[node_count] = @intCast(component_count);
        node_count += 1;
        var i = component_count;
        while (i > 0) { i -= 1; tasks[top] = components[i]; top += 1; }
    }

    var words: [MAX_NODES + 1]i64 = @splat(0);
    var word_count: usize = 1;
    if (compatible) {
        words[0] = @intCast(node_count);
        for (0..node_count) |i| {
            words[i + 1] = if (kind[i] == 1) -(@as(i64, node_value[i]) + 1) else @as(i64, node_value[i]);
        }
        word_count += node_count;
    }
    const bytes = word_count * 8;
    if (output == null or output_capacity < bytes) return -2;
    for (0..word_count) |i| storeWord(output.?, i * 8, words[i]);
    return @intCast(bytes);
}
