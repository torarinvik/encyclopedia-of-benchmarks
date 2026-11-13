const B: usize = 4;
const MAX_INITIAL: usize = 16;
const MAX_OPS: usize = 64;
const MAX_INSERTS: usize = 32;
const MAX_ACCESSES: usize = 32;
const MAX_NODES: usize = 16;
const MAX_ITEMS: usize = 48;
const MAX_PARSEABLE: usize = 179;

fn validInput(values: []const i64) ?usize {
    if (values.len < 2 or values.len > MAX_PARSEABLE or values[0] < 0 or values[0] > MAX_INITIAL) return null;
    const initial: usize = @intCast(values[0]);
    if (values.len < initial + 2) return null;
    for (values[1 .. 1 + initial]) |value| if (value < -1_000_000 or value > 1_000_000) return null;
    const raw_ops = values[1 + initial];
    if (raw_ops < 0 or raw_ops > MAX_OPS) return null;
    var cursor = initial + 2;
    var size = initial;
    var inserts: usize = 0;
    var accesses: usize = 0;
    for (0..@intCast(raw_ops)) |_| {
        if (cursor >= values.len) return null;
        if (values[cursor] == 0) {
            if (cursor + 3 > values.len) return null;
            const index = values[cursor + 1]; const value = values[cursor + 2];
            if (index < 0 or @as(u64, @intCast(index)) > size or value < -1_000_000 or value > 1_000_000) return null;
            inserts += 1; if (inserts > MAX_INSERTS) return null;
            size += 1; cursor += 3;
        } else if (values[cursor] == 1) {
            if (cursor + 2 > values.len) return null;
            const index = values[cursor + 1];
            if (index < 0 or @as(u64, @intCast(index)) >= size) return null;
            accesses += 1; if (accesses > MAX_ACCESSES) return null;
            cursor += 2;
        } else return null;
    }
    if (cursor != values.len or size > MAX_ITEMS) return null;
    return accesses;
}

fn blockInsert(blocks: *[MAX_NODES][2 * B + 1]i64, sizes: *[MAX_NODES]usize,
               next: *[MAX_NODES]i32, node_count: *usize, index: usize, value: i64) void {
    var node: usize = 0; var offset: usize = 0;
    while (next[node] >= 0 and index > offset + sizes[node]) { offset += sizes[node]; node = @intCast(next[node]); }
    const local = index - offset;
    var j = sizes[node];
    while (j > local) : (j -= 1) blocks[node][j] = blocks[node][j - 1];
    blocks[node][local] = value; sizes[node] += 1;
    if (sizes[node] > 2 * B) {
        const fresh = node_count.*; node_count.* += 1;
        const first = sizes[node] - B;
        for (0..B) |k| blocks[fresh][k] = blocks[node][first + k];
        sizes[fresh] = B; sizes[node] -= B;
        next[fresh] = next[node]; next[node] = @intCast(fresh);
    }
}

fn blockGet(blocks: *const [MAX_NODES][2 * B + 1]i64, sizes: *const [MAX_NODES]usize,
            next: *const [MAX_NODES]i32, index: usize) i64 {
    var node: usize = 0; var offset: usize = 0;
    while (index >= offset + sizes[node]) { offset += sizes[node]; node = @intCast(next[node]); }
    return blocks[node][index - offset];
}

export fn indexed_block_list(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const values = input[0..length];
    const access_count = validInput(values) orelse return -1;
    if (access_count == 0) return 0;
    const required = 8 * access_count;
    if (output == null or capacity < required) return -2;
    var blocks: [MAX_NODES][2 * B + 1]i64 = @splat(@splat(0));
    var sizes: [MAX_NODES]usize = @splat(0);
    var next: [MAX_NODES]i32 = @splat(-1);
    var node_count: usize = 1;
    const initial: usize = @intCast(values[0]);
    for (0..initial) |i| blockInsert(&blocks, &sizes, &next, &node_count, i, values[1 + i]);
    const operation_count: usize = @intCast(values[1 + initial]);
    var cursor = initial + 2; var answer_count: usize = 0;
    var answers: [MAX_ACCESSES]i64 = @splat(0);
    for (0..operation_count) |_| {
        const opcode = values[cursor]; const index: usize = @intCast(values[cursor + 1]);
        if (opcode == 0) { blockInsert(&blocks, &sizes, &next, &node_count, index, values[cursor + 2]); cursor += 3; }
        else { answers[answer_count] = blockGet(&blocks, &sizes, &next, index); answer_count += 1; cursor += 2; }
    }
    const out = output[0..required];
    for (0..answer_count) |i| {
        const bytes = @as(u64, @bitCast(answers[i]));
        for (0..8) |b| out[8 * i + b] = @truncate(bytes >> @intCast(8 * b));
    }
    return @intCast(required);
}
