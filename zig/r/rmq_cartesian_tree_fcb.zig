const N: usize = 64;
const Q: usize = 64;
const E: usize = 127;
const B: usize = 127;
const L: usize = 8;
const M: usize = 4;

fn shallower(a: usize, b: usize, depth: *const [E]u16) usize {
    if (depth[a] < depth[b] or (depth[a] == depth[b] and a < b)) return a;
    return b;
}

fn rangeMinimum(a: usize, z: usize, ec: usize, bs: usize, depth: *const [E]u16,
    pat: *const [B]u8, micro: *const [8][M][M]u8, macro: *const [L][B]u16,
    logs: *const [B + 1]u8) usize {
    const ba = a / bs; const bz = z / bs; const oa = a % bs; const oz = z % bs;
    if (ba == bz) return ba * bs + micro[pat[ba]][oa][oz];
    const xa = ba * bs; const xz = bz * bs; const na = @min(bs, ec - xa);
    var best = xa + micro[pat[ba]][oa][na - 1];
    best = shallower(best, xz + micro[pat[bz]][0][oz], depth);
    if (bz > ba + 1) {
        const lo = ba + 1; const hi = bz - 1; const k: usize = logs[hi - lo + 1];
        const span = @as(usize, 1) << @intCast(k);
        best = shallower(best, macro[k][lo], depth);
        best = shallower(best, macro[k][hi - span + 1], depth);
    }
    return best;
}

export fn rmq_cartesian_tree_fcb(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 195) return -1;
    if (input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 64) return -1;
    const n: usize = @intCast(input[0]); const q: usize = @intCast(input[1]); const qo = 2 + n;
    if (length != qo + 2 * q) return -1;
    var values: [N]i64 = @splat(0);
    for (0..n) |i| { values[i] = input[2 + i]; if (values[i] < -1000 or values[i] > 1000) return -1; }
    for (0..q) |i| { const a = input[qo + 2*i]; const z = input[qo + 2*i + 1]; if (a < 0 or a > z or z >= @as(i64, @intCast(n))) return -1; }
    if (output == null or output_capacity < q + 1) return -2;

    var left: [N]i32 = @splat(-1); var right: [N]i32 = @splat(-1);
    var parent: [N]i32 = @splat(-1); var mono: [N]usize = @splat(0);
    var top: usize = 0;
    for (0..n) |i| {
        var last: i32 = -1;
        while (top > 0 and values[mono[top - 1]] > values[i]) { top -= 1; last = @intCast(mono[top]); }
        if (top > 0) { const p = mono[top - 1]; right[p] = @intCast(i); parent[i] = @intCast(p); }
        if (last >= 0) { left[i] = last; parent[@intCast(last)] = @intCast(i); }
        mono[top] = i; top += 1;
    }
    var root: usize = 0; while (parent[root] >= 0) { root += 1; }
    var euler: [E]u16 = @splat(0); var depth: [E]u16 = @splat(0);
    var first: [N]usize = @splat(0); var node_depth: [N]u16 = @splat(0);
    var fnodes: [N]usize = @splat(0); var state: [N]u8 = @splat(0);
    var ec: usize = 1; var sp: usize = 1; euler[0] = @intCast(root); depth[0] = 0; first[root] = 0; node_depth[root] = 0; fnodes[0] = root;
    while (sp > 0) {
        const slot = sp - 1; const v = fnodes[slot];
        if (state[slot] == 0) {
            if (left[v] >= 0) { const c: usize = @intCast(left[v]); state[slot] = 1; node_depth[c] = node_depth[v] + 1; first[c] = ec; euler[ec] = @intCast(c); depth[ec] = node_depth[c]; ec += 1; fnodes[sp] = c; state[sp] = 0; sp += 1; }
            else if (right[v] >= 0) { const c: usize = @intCast(right[v]); state[slot] = 2; node_depth[c] = node_depth[v] + 1; first[c] = ec; euler[ec] = @intCast(c); depth[ec] = node_depth[c]; ec += 1; fnodes[sp] = c; state[sp] = 0; sp += 1; }
            else sp -= 1;
        } else if (state[slot] == 1) {
            euler[ec] = @intCast(v); depth[ec] = node_depth[v]; ec += 1;
            if (right[v] >= 0) { const c: usize = @intCast(right[v]); state[slot] = 2; node_depth[c] = node_depth[v] + 1; first[c] = ec; euler[ec] = @intCast(c); depth[ec] = node_depth[c]; ec += 1; fnodes[sp] = c; state[sp] = 0; sp += 1; } else sp -= 1;
        } else { euler[ec] = @intCast(v); depth[ec] = node_depth[v]; ec += 1; sp -= 1; }
    }
    var lg: usize = 0; var x = ec; while (x > 1) { x /= 2; lg += 1; }
    const bs = @max(1, lg / 2); const blocks = (ec + bs - 1) / bs;
    var micro: [8][M][M]u8 = @splat(@splat(@splat(0))); var pat: [B]u8 = @splat(0);
    var logs: [B + 1]u8 = @splat(0); var macro: [L][B]u16 = @splat(@splat(0));
    const shapes = @as(usize, 1) << @intCast(bs - 1);
    for (0..shapes) |shape| { var rel: [M]i32 = @splat(0); for (0..bs - 1) |j| { rel[j + 1] = rel[j] + (if ((shape >> j) & 1 != 0) @as(i32, 1) else -1); }
        for (0..bs) |a| { var z = a; while (z < bs) : (z += 1) { var best = a; var k = a + 1; while (k <= z) : (k += 1) { if (rel[k] < rel[best]) best = k; } micro[shape][a][z] = @intCast(best); } } }
    for (0..blocks) |b| { const base = b * bs; const end = @min(ec, base + bs); var best = base; var j = base; while (j + 1 < end) : (j += 1) { if (depth[j + 1] > depth[j]) pat[b] |= @as(u8, 1) << @intCast(j - base); best = shallower(best, j + 1, &depth); } macro[0][b] = @intCast(best); }
    for (2..blocks + 1) |c| { logs[c] = logs[c / 2] + 1; }
    var level: usize = 1; while ((@as(usize, 1) << @intCast(level)) <= blocks and level < L) : (level += 1) { const half = @as(usize, 1) << @intCast(level - 1); const span = 2 * half; var b: usize = 0; while (b + span <= blocks) : (b += 1) macro[level][b] = @intCast(shallower(macro[level - 1][b], macro[level - 1][b + half], &depth)); }
    var answers: [Q]u8 = @splat(0);
    for (0..q) |i| { const a = first[@intCast(input[qo + 2*i])]; const z = first[@intCast(input[qo + 2*i + 1])]; const at = rangeMinimum(@min(a,z), @max(a,z), ec, bs, &depth, &pat, &micro, &macro, &logs); answers[i] = @intCast(euler[at]); }
    output[0] = @intCast(q); for (0..q) |i| output[i+1] = answers[i]; return @intCast(q + 1);
}
