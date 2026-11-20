const MAX_VERTICES: usize = 256;
const MAX_WORDS: usize = 4;
const MAX_CELLS: usize = MAX_VERTICES * MAX_WORDS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1026;

fn writeU16Le(output: [*]u8, position: usize, value: u16) void {
    output[position] = @truncate(value);
    output[position + 1] = @truncate(value >> 8);
}

export fn kosaraju_dense_bitset_scc(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_VERTICES))) return -1;
    const n: usize = @intCast(input[0]);
    const words = (n + 63) / 64;
    if (length != 1 + n * words) return -1;

    var adjacency: [MAX_CELLS]u64 = @splat(0);
    var transpose: [MAX_CELLS]u64 = @splat(0);
    for (0..n * words) |cell| adjacency[cell] = @bitCast(input[1 + cell]);
    if ((n & 63) != 0) {
        const valid = (@as(u64, 1) << @intCast(n & 63)) - 1;
        for (0..n) |vertex| {
            if ((adjacency[vertex * words + words - 1] & ~valid) != 0) return -1;
        }
    }
    for (0..n) |source| {
        for (0..words) |word| {
            var bits = adjacency[source * words + word];
            while (bits != 0) {
                const bit: usize = @intCast(@ctz(bits));
                const target = word * 64 + bit;
                transpose[target * words + source / 64] |= @as(u64, 1) << @intCast(source & 63);
                bits &= bits - 1;
            }
        }
    }

    var unvisited: [MAX_WORDS]u64 = @splat(0);
    for (0..words) |word| unvisited[word] = ~@as(u64, 0);
    if ((n & 63) != 0) unvisited[words - 1] = (@as(u64, 1) << @intCast(n & 63)) - 1;
    var stack: [MAX_VERTICES]u16 = @splat(0);
    var next_word: [MAX_VERTICES]u16 = @splat(0);
    var order: [MAX_VERTICES]u16 = @splat(0);
    var order_length: usize = 0;
    for (0..n) |root| {
        const root_word = root / 64;
        const root_bit = root & 63;
        if (((unvisited[root_word] >> @intCast(root_bit)) & 1) == 0) continue;
        unvisited[root_word] &= ~(@as(u64, 1) << @intCast(root_bit));
        var stack_length: usize = 1;
        stack[0] = @intCast(root);
        next_word[0] = 0;
        while (stack_length != 0) {
            const depth = stack_length - 1;
            const vertex: usize = @intCast(stack[depth]);
            var pushed = false;
            while (@as(usize, next_word[depth]) < words) {
                const word: usize = @intCast(next_word[depth]);
                const candidates = adjacency[vertex * words + word] & unvisited[word];
                if (candidates != 0) {
                    const bit: usize = @intCast(@ctz(candidates));
                    const neighbor = word * 64 + bit;
                    unvisited[word] &= ~(@as(u64, 1) << @intCast(bit));
                    stack[stack_length] = @intCast(neighbor);
                    next_word[stack_length] = 0;
                    stack_length += 1;
                    pushed = true;
                    break;
                }
                next_word[depth] += 1;
            }
            if (!pushed and @as(usize, next_word[depth]) == words) {
                order[order_length] = @intCast(vertex);
                order_length += 1;
                stack_length -= 1;
            }
        }
    }

    for (0..words) |word| unvisited[word] = ~@as(u64, 0);
    if ((n & 63) != 0) unvisited[words - 1] = (@as(u64, 1) << @intCast(n & 63)) - 1;
    var raw_component: [MAX_VERTICES]u16 = @splat(0);
    var component_count: u16 = 0;
    while (order_length != 0) {
        order_length -= 1;
        const root: usize = @intCast(order[order_length]);
        const root_word = root / 64;
        const root_bit = root & 63;
        if (((unvisited[root_word] >> @intCast(root_bit)) & 1) == 0) continue;
        unvisited[root_word] &= ~(@as(u64, 1) << @intCast(root_bit));
        var stack_length: usize = 1;
        stack[0] = @intCast(root);
        raw_component[root] = component_count;
        while (stack_length != 0) {
            stack_length -= 1;
            const vertex: usize = @intCast(stack[stack_length]);
            for (0..words) |word| {
                var candidates = transpose[vertex * words + word] & unvisited[word];
                while (candidates != 0) {
                    const bit: usize = @intCast(@ctz(candidates));
                    const neighbor = word * 64 + bit;
                    const selected = @as(u64, 1) << @intCast(bit);
                    unvisited[word] &= ~selected;
                    candidates &= ~selected;
                    raw_component[neighbor] = component_count;
                    stack[stack_length] = @intCast(neighbor);
                    stack_length += 1;
                }
            }
        }
        component_count += 1;
    }

    var remap: [MAX_VERTICES]u16 = @splat(0xffff);
    var canonical_count: u16 = 0;
    for (0..n) |vertex| {
        const raw: usize = @intCast(raw_component[vertex]);
        if (remap[raw] == 0xffff) {
            remap[raw] = canonical_count;
            canonical_count += 1;
        }
    }
    const output_length = 2 + 2 * n;
    if (output_opt == null or output_capacity < output_length) return -2;
    const output = output_opt.?;
    writeU16Le(output, 0, canonical_count);
    for (0..n) |vertex| writeU16Le(output, 2 + 2 * vertex,
        remap[@intCast(raw_component[vertex])]);
    return @intCast(output_length);
}
