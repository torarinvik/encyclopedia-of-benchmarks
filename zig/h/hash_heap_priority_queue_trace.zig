const Item = struct { key: u8 = 0, insertion: u8 = 0 };
const MaxBuckets = 8;
const MaxOps = 64;

fn before(a: Item, b: Item) bool {
    return a.key < b.key or (a.key == b.key and a.insertion < b.insertion);
}
fn push(heaps: *[MaxBuckets][MaxOps]Item, sizes: *[MaxBuckets]usize, bucket: usize, item: Item) void {
    var child = sizes[bucket]; sizes[bucket] += 1; heaps[bucket][child] = item;
    while (child > 0) {
        const parent = (child - 1) / 2;
        if (!before(heaps[bucket][child], heaps[bucket][parent])) break;
        const tmp = heaps[bucket][child]; heaps[bucket][child] = heaps[bucket][parent]; heaps[bucket][parent] = tmp;
        child = parent;
    }
}
fn pop(heaps: *[MaxBuckets][MaxOps]Item, sizes: *[MaxBuckets]usize, bucket: usize) void {
    sizes[bucket] -= 1; const last = sizes[bucket]; if (last == 0) return;
    heaps[bucket][0] = heaps[bucket][last]; var parent: usize = 0;
    while (true) {
        const left = parent * 2 + 1; if (left >= last) break;
        var child = left; const right = left + 1;
        if (right < last and before(heaps[bucket][right], heaps[bucket][left])) child = right;
        if (!before(heaps[bucket][child], heaps[bucket][parent])) break;
        const tmp = heaps[bucket][child]; heaps[bucket][child] = heaps[bucket][parent]; heaps[bucket][parent] = tmp;
        parent = child;
    }
}
fn writeI64Le(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn hash_heap_priority_queue_trace(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 132) return -1;
    const values = input.?[0..length];
    const u = values[0]; const b = values[1]; const qv = values[2];
    if (u < 1 or u > 128 or b < 1 or b > 8 or b > u or qv < 0 or qv > MaxOps) return -1;
    const universe: usize = @intCast(u); const bucket_count: usize = @intCast(b); const q: usize = @intCast(qv);
    if (length != 3 + 2 * q) return -1;
    var ops: [MaxOps]u8 = @splat(0); var args: [MaxOps]u8 = @splat(0);
    for (0..q) |op| {
        const opcode = values[3 + 2 * op]; const argument = values[4 + 2 * op];
        if (opcode == 0) { if (argument < 0 or argument >= u) return -1; }
        else if (opcode == 1 or opcode == 2) { if (argument != 0) return -1; }
        else return -1;
        ops[op] = @intCast(opcode); args[op] = @intCast(argument);
    }
    var heaps: [MaxBuckets][MaxOps]Item = @splat(@splat(.{}));
    var sizes: [MaxBuckets]usize = @splat(0);
    var words: [MaxOps + 1]i64 = @splat(0);
    words[0] = @intCast(q);
    for (0..q) |op| {
        if (ops[op] == 0) {
            const bucket = @as(usize, args[op]) * bucket_count / universe;
            push(&heaps, &sizes, bucket, .{ .key = args[op], .insertion = @intCast(op) });
            words[op + 1] = -2;
            continue;
        }
        var bucket: usize = 0;
        while (bucket < bucket_count and sizes[bucket] == 0) : (bucket += 1) {}
        if (bucket == bucket_count) { words[op + 1] = -1; continue; }
        const item = heaps[bucket][0]; words[op + 1] = (@as(i64, item.insertion) << 8) | @as(i64, item.key);
        if (ops[op] == 2) pop(&heaps, &sizes, bucket);
    }
    const required = (q + 1) * 8;
    if (output == null or capacity < required) return -2;
    var staged: [520]u8 = @splat(0);
    for (0..q + 1) |index| writeI64Le(&staged, index * 8, words[index]);
    for (0..required) |byte| output.?[byte] = staged[byte];
    return @intCast(required);
}
