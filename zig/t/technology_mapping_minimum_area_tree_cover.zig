const MaxN = 31;
const MaxOutput = 256;
const Inf: i64 = 2305843009213693951;
fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn technology_mapping_minimum_area_tree_cover(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 9 or length > 99) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 31) return -1;
    const n: usize = @intCast(input[0]); if (length != 6 + 3 * n) return -1;
    var costs: [5]i64 = @splat(0);
    for (0..5) |p| { costs[p] = input[1 + p]; if (costs[p] != -1 and (costs[p] < 1 or costs[p] > 1_000_000)) return -1; }
    var kind: [MaxN]i32 = @splat(0); var left: [MaxN]i32 = @splat(-1); var right: [MaxN]i32 = @splat(-1); var parents: [MaxN]i32 = @splat(0);
    for (0..n) |i| {
        const at = 6 + 3 * i; const k = input[at]; const l = input[at + 1]; const r = input[at + 2];
        if (k < 0 or k > 2) return -1; kind[i] = @intCast(k);
        if (k == 0) { if (l != -1 or r != -1) return -1; }
        else if (k == 1) { if (l <= @as(i64, @intCast(i)) or l >= @as(i64, @intCast(n)) or r != -1) return -1; left[i] = @intCast(l); parents[@intCast(l)] += 1; }
        else { if (l <= @as(i64, @intCast(i)) or l >= @as(i64, @intCast(n)) or r <= @as(i64, @intCast(i)) or r >= @as(i64, @intCast(n)) or l == r) return -1; left[i] = @intCast(l); right[i] = @intCast(r); parents[@intCast(l)] += 1; parents[@intCast(r)] += 1; }
    }
    if (parents[0] != 0) return -1; for (1..n) |i| if (parents[i] != 1) return -1;
    var best: [MaxN]i64 = @splat(Inf); var choice: [MaxN]i32 = @splat(-1);
    var rev = n; while (rev > 0) { rev -= 1; const i = rev;
        if (kind[i] == 0) { best[i] = 0; continue; }
        const l: usize = @intCast(left[i]); const r: usize = @intCast(right[i]); var candidate: i64 = 0;
        if (kind[i] == 1) { if (costs[0] >= 0) { candidate = costs[0] + best[l]; if (candidate < Inf and candidate < best[i]) { best[i] = candidate; choice[i] = 0; } } }
        else {
            if (costs[1] >= 0) { candidate = costs[1] + best[l] + best[r]; if (candidate < Inf and candidate < best[i]) { best[i] = candidate; choice[i] = 1; } }
            if (costs[2] >= 0 and kind[l] == 1) { candidate = costs[2] + best[@intCast(left[l])] + best[r]; if (candidate < Inf and candidate < best[i]) { best[i] = candidate; choice[i] = 2; } }
            if (costs[3] >= 0 and kind[r] == 1) { candidate = costs[3] + best[l] + best[@intCast(left[r])]; if (candidate < Inf and candidate < best[i]) { best[i] = candidate; choice[i] = 3; } }
            if (costs[4] >= 0 and kind[l] == 1 and kind[r] == 1) { candidate = costs[4] + best[@intCast(left[l])] + best[@intCast(left[r])]; if (candidate < Inf and candidate < best[i]) { best[i] = candidate; choice[i] = 4; } }
        }
    }
    if (best[0] == Inf) return -1;
    var mapping: [MaxN]i64 = @splat(-3); for (0..n) |i| if (kind[i] == 0) { mapping[i] = -1; };
    var stack: [2 * MaxN]usize = @splat(0); var top: usize = 0; if (kind[0] != 0) { stack[top] = 0; top += 1; }
    while (top > 0) { top -= 1; const node = stack[top]; const p = choice[node]; const l: usize = @intCast(left[node]); const r: usize = if (right[node] < 0) 0 else @intCast(right[node]); mapping[node] = p;
        if (p == 0) { stack[top] = l; top += 1; }
        else if (p == 1) { stack[top] = l; top += 1; stack[top] = r; top += 1; }
        else if (p == 2) { mapping[l] = -2; stack[top] = @intCast(left[l]); top += 1; stack[top] = r; top += 1; }
        else if (p == 3) { mapping[r] = -2; stack[top] = l; top += 1; stack[top] = @intCast(left[r]); top += 1; }
        else { mapping[l] = -2; mapping[r] = -2; stack[top] = @intCast(left[l]); top += 1; stack[top] = @intCast(left[r]); top += 1; }
    }
    const bytes = 8 * (n + 1); if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0); putI64(&staged, 0, best[0]); for (0..n) |i| putI64(&staged, 8 * (i + 1), mapping[i]);
    const output = output_opt.?; @memcpy(output[0..bytes], staged[0..bytes]); return @intCast(bytes);
}
