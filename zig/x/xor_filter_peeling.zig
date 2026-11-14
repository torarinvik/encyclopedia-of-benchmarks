pub export fn xor_filter_peeling(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 259 or input[0] < 0 or input[0] > 32 or input[1] < 3 or input[1] > 96 or input[2] < 0 or input[2] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const slots: usize = @intCast(input[1]);
    const q: usize = @intCast(input[2]);
    if (length != 3+4*(n+q)) return -1;
    for (0..n+q) |i| {
        const at = 3+4*i;
        const a = input[at]; const b = input[at+1]; const c = input[at+2]; const f = input[at+3];
        if (a < 0 or a >= @as(i64, @intCast(slots)) or b < 0 or b >= @as(i64, @intCast(slots)) or c < 0 or c >= @as(i64, @intCast(slots)) or a == b or a == c or b == c or f < 0 or f > 255) return -1;
    }
    var degree: [96]usize = @splat(0);
    var edge_xor: [96]usize = @splat(0);
    var queue: [96]usize = @splat(0);
    var table: [96]i64 = @splat(0);
    var stack_slot: [32]usize = @splat(0);
    var stack_edge: [32]usize = @splat(0);
    for (0..n) |edge| {
        for (0..3) |j| {
            const slot: usize = @intCast(input[3+4*edge+j]);
            degree[slot] += 1;
            edge_xor[slot] ^= edge;
        }
    }
    var head: usize = 0;
    var tail: usize = 0;
    var used: usize = 0;
    for (0..slots) |slot| { if (degree[slot] == 1) { queue[tail] = slot; tail += 1; } }
    while (head < tail) {
        const slot = queue[head]; head += 1;
        if (degree[slot] != 1) continue;
        const edge = edge_xor[slot];
        stack_slot[used] = slot; stack_edge[used] = edge; used += 1;
        for (0..3) |j| {
            const v: usize = @intCast(input[3+4*edge+j]);
            degree[v] -= 1;
            edge_xor[v] ^= edge;
            if (degree[v] == 1) { queue[tail] = v; tail += 1; }
        }
    }
    if (used != n) return -2;
    while (used > 0) {
        used -= 1;
        const at = 3+4*stack_edge[used];
        const a: usize = @intCast(input[at]); const b: usize = @intCast(input[at+1]); const c: usize = @intCast(input[at+2]);
        table[stack_slot[used]] = input[at+3] ^ table[a] ^ table[b] ^ table[c];
    }
    var result: i64 = 0;
    for (0..q) |i| {
        const at = 3+4*(n+i);
        const a: usize = @intCast(input[at]); const b: usize = @intCast(input[at+1]); const c: usize = @intCast(input[at+2]);
        if ((table[a] ^ table[b] ^ table[c]) == input[at+3]) result += @intCast(i+1);
    }
    return result;
}
