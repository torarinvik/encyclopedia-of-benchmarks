// Clean-room finite-metric work-function algorithm profile.
const std = @import("std");
const MAX_P: usize = 6;
const MAX_K: usize = 3;
const MAX_R: usize = 8;
const MAX_CONFIGS: usize = 20;
const MAX_INPUT: usize = 50;
const Config = [MAX_K]i64;

fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn sortConfig(value: *Config, k: usize) void {
    for (0..k) |i| {
        var j = i + 1;
        while (j < k) : (j += 1) if (value[j] < value[i]) {
            const tmp = value[i]; value[i] = value[j]; value[j] = tmp;
        };
    }
}

fn findConfig(configs: *const [MAX_CONFIGS]Config, count: usize, value: *const Config, k: usize) usize {
    for (0..count) |i| {
        var same = true;
        for (0..k) |j| if (configs[i][j] != value[j]) { same = false; };
        if (same) return i;
    }
    return count;
}

fn configDistance(a: *const Config, b: *const Config, k: usize, metric: *const [MAX_P][MAX_P]i64) i64 {
    if (k == 1) return metric[@intCast(a[0])][@intCast(b[0])];
    if (k == 2) {
        const first = metric[@intCast(a[0])][@intCast(b[0])] + metric[@intCast(a[1])][@intCast(b[1])];
        const second = metric[@intCast(a[0])][@intCast(b[1])] + metric[@intCast(a[1])][@intCast(b[0])];
        return @min(first, second);
    }
    const perms = [_][3]usize{ .{0,1,2}, .{0,2,1}, .{1,0,2}, .{1,2,0}, .{2,0,1}, .{2,1,0} };
    var best: i64 = std.math.maxInt(i64);
    for (perms) |perm| {
        const cost = metric[@intCast(a[0])][@intCast(b[perm[0]])] + metric[@intCast(a[1])][@intCast(b[perm[1]])] + metric[@intCast(a[2])][@intCast(b[perm[2]])];
        best = @min(best, cost);
    }
    return best;
}

export fn work_function_k_server(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const p64 = input[0]; const k64 = input[1]; const n64 = input[2];
    if (p64 < 2 or p64 > 6 or k64 < 1 or k64 > 3 or k64 > p64 or n64 < 0 or n64 > 8) return -1;
    const p: usize = @intCast(p64); const k: usize = @intCast(k64); const n: usize = @intCast(n64);
    const initial_at = 3 + p*p; const requests_at = initial_at + k;
    if (length != requests_at + n) return -1;
    var metric: [MAX_P][MAX_P]i64 = @splat(@splat(0));
    for (0..p) |i| for (0..p) |j| {
        const x = input[3 + i*p + j];
        if (x < 0 or x > 1000 or (i == j and x != 0) or (i != j and x == 0)) return -1;
        metric[i][j] = x;
    };
    for (0..p) |i| for (0..p) |j| {
        if (metric[i][j] != metric[j][i]) return -1;
        for (0..p) |z| if (metric[i][j] > metric[i][z] + metric[z][j]) return -1;
    };
    var initial: Config = @splat(0);
    for (0..k) |i| {
        initial[i] = input[initial_at+i];
        if (initial[i] < 0 or initial[i] >= p64) return -1;
        for (0..i) |j| if (initial[j] == initial[i]) return -1;
    }
    sortConfig(&initial, k);
    var requests: [MAX_R]i64 = @splat(0);
    for (0..n) |t| { requests[t] = input[requests_at+t]; if (requests[t] < 0 or requests[t] >= p64) return -1; }
    const output_bytes = 8 * (2 + n*k);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var configs: [MAX_CONFIGS]Config = @splat(@splat(0));
    var count: usize = 0;
    for (0..p) |a| {
        if (k == 1) { configs[count][0] = @intCast(a); count += 1; continue; }
        var b = a + 1;
        while (b < p) : (b += 1) {
            if (k == 2) { configs[count][0] = @intCast(a); configs[count][1] = @intCast(b); count += 1; continue; }
            var c = b + 1;
            while (c < p) : (c += 1) { configs[count] = .{@intCast(a), @intCast(b), @intCast(c)}; count += 1; }
        }
    }
    var work: [MAX_CONFIGS]i64 = @splat(0); var next: [MAX_CONFIGS]i64 = @splat(0);
    for (0..count) |x| work[x] = configDistance(&initial, &configs[x], k, &metric);
    var staged: [2 + MAX_R*MAX_K]i64 = @splat(0); staged[0] = @intCast(n); staged[1] = @intCast(k);
    var current = initial;
    for (0..n) |t| {
        const r = requests[t];
        for (0..count) |x| {
            next[x] = std.math.maxInt(i64);
            for (0..count) |y| {
                var contains = false;
                for (0..k) |j| if (configs[y][j] == r) { contains = true; };
                if (contains) next[x] = @min(next[x], work[y] + configDistance(&configs[y], &configs[x], k, &metric));
            }
        }
        var chosen = current;
        var occupied = false;
        for (0..k) |j| if (current[j] == r) { occupied = true; };
        if (!occupied) {
            var best: i64 = std.math.maxInt(i64); var best_slot: usize = 0;
            for (0..k) |slot| {
                var candidate = current; candidate[slot] = r; sortConfig(&candidate, k);
                const idx = findConfig(&configs, count, &candidate, k);
                const score = work[idx] + metric[@intCast(current[slot])][@intCast(r)];
                if (score < best or (score == best and slot < best_slot)) { best = score; best_slot = slot; chosen = candidate; }
            }
        }
        for (0..k) |j| { staged[2+t*k+j] = chosen[j]; current[j] = chosen[j]; }
        for (0..count) |x| work[x] = next[x];
    }
    for (0..2+n*k) |i| putI64(output, 8*i, staged[i]);
    return @intCast(output_bytes);
}
