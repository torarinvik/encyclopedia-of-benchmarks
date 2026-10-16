export fn fifocache(input: ?[*]const i64, n: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or n < 2 or n > 26) return -1;
    const a = input.?;
    const c = a[0];
    const ops = a[1];
    if (c < 1 or c > 6 or ops < 0 or ops > 8 or n != 2 + 3 * @as(usize, @intCast(ops))) return -1;
    var keys: [6]i64 = @splat(0);
    var vals: [6]i64 = @splat(0);
    var queries: [8]u8 = @splat(0);
    var size: usize = 0;
    var gets: usize = 0;
    var hits: u8 = 0;
    var misses: u8 = 0;
    for (0..@intCast(ops)) |i| {
        const op = a[2 + 3 * i];
        const key = a[3 + 3 * i];
        const value = a[4 + 3 * i];
        if (key < 0 or key > 15 or (op != 0 and op != 1)) return -1;
        if (op == 0) {
            if (value < 0 or value > 255) return -1;
            var j: usize = 0;
            while (j < size and keys[j] != key) : (j += 1) {}
            if (j < size) {
                for (j + 1..size) |t| { keys[t - 1] = keys[t]; vals[t - 1] = vals[t]; }
                size -= 1;
            }
            if (size == @as(usize, @intCast(c))) {
                for (1..size) |t| { keys[t - 1] = keys[t]; vals[t - 1] = vals[t]; }
                size -= 1;
            }
            keys[size] = key;
            vals[size] = value;
            size += 1;
        } else {
            if (value != 0) return -1;
            var j: usize = 0;
            while (j < size and keys[j] != key) : (j += 1) {}
            if (j < size) { hits += 1; queries[gets] = @intCast(vals[j]); }
            else { misses += 1; queries[gets] = 255; }
            gets += 1;
        }
    }
    const need = 4 + gets + 2 * size;
    if (output == null or capacity < need) return -2;
    const out = output.?;
    out[0] = hits;
    out[1] = misses;
    out[2] = @intCast(size);
    out[3] = @intCast(gets);
    for (0..gets) |i| out[4 + i] = queries[i];
    for (0..size) |i| { out[4 + gets + 2 * i] = @intCast(keys[i]); out[5 + gets + 2 * i] = @intCast(vals[i]); }
    return @intCast(need);
}
