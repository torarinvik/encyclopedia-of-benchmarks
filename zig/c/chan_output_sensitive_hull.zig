// Unverified Chan hull draft; no compiler or benchmark has been run.
const Point = [2]i64;

fn turn(a: Point, b: Point, c: Point) i64 {
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0]);
}
fn less(a: Point, b: Point) bool {
    return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]);
}
fn groupHull(points: *const [32]Point, begin: usize, count: usize, out: []usize) usize {
    var order: [32]usize = undefined;
    var scratch: [32]usize = undefined;
    var chain: [64]usize = undefined;
    for (0..count) |i| order[i] = begin+i;
    var width: usize = 1;
    while (width < count) : (width *= 2) {
        var block: usize = 0;
        while (block < count) : (block += 2*width) {
            const middle = @min(block+width, count);
            const end = @min(block+2*width, count);
            var left = block;
            var right = middle;
            var dest = block;
            while (left < middle and right < end) : (dest += 1) {
                if (less(points[order[right]], points[order[left]])) {
                    scratch[dest] = order[right]; right += 1;
                } else { scratch[dest] = order[left]; left += 1; }
            }
            while (left < middle) : (left += 1) { scratch[dest] = order[left]; dest += 1; }
            while (right < end) : (right += 1) { scratch[dest] = order[right]; dest += 1; }
        }
        for (0..count) |i| order[i] = scratch[i];
    }
    if (count == 1) { out[0] = order[0]; return 1; }
    var used: usize = 0;
    for (0..count) |i| {
        while (used >= 2 and turn(points[chain[used-2]], points[chain[used-1]], points[order[i]]) <= 0) used -= 1;
        chain[used] = order[i]; used += 1;
    }
    const lower = used;
    var i = count-1;
    while (i > 0) {
        i -= 1;
        while (used > lower and turn(points[chain[used-2]], points[chain[used-1]], points[order[i]]) <= 0) used -= 1;
        chain[used] = order[i]; used += 1;
    }
    used -= 1;
    for (0..used) |j| out[j] = chain[j];
    return used;
}
fn tangent(points: *const [32]Point, hull: []const usize, query: usize) ?usize {
    const n = hull.len;
    if (n == 1) return hull[0];
    if (n == 2) return if (turn(points[query], points[hull[0]], points[hull[1]]) > 0) hull[0] else hull[1];
    const initial_up = turn(points[query], points[hull[0]], points[hull[1]]) > 0;
    var lo: usize = 0;
    var hi = n;
    while (lo < hi) {
        const mid = lo + (hi-lo)/2;
        const before = turn(points[query], points[hull[mid]], points[hull[(mid+n-1)%n]]) > 0;
        const after = turn(points[query], points[hull[mid]], points[hull[(mid+1)%n]]) > 0;
        if (before and after) return hull[mid];
        const below_anchor = mid != 0 and turn(points[query], points[hull[mid]], points[hull[0]]) > 0;
        const above_anchor = mid != 0 and turn(points[query], points[hull[0]], points[hull[mid]]) > 0;
        const left = if (initial_up) after and below_anchor else after or above_anchor;
        if (left) { hi = mid; } else { lo = mid+1; }
    }
    return null;
}

export fn chan_output_sensitive_hull(input_opt: ?[*]const i64, length: usize,
                                      output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > 32) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1+2*n) return -1;
    var points: [32]Point = undefined;
    for (0..n) |i| {
        points[i] = .{ input[1+2*i], input[2+2*i] };
        if (points[i][0] < -1000 or points[i][0] > 1000 or points[i][1] < -1000 or points[i][1] > 1000) return -1;
        for (0..i) |j| {
            if (points[i][0] == points[j][0] and points[i][1] == points[j][1]) return -1;
        }
    }
    for (0..n) |i| {
        for (i+1..n) |j| {
            for (j+1..n) |k| {
                if (turn(points[i], points[j], points[k]) == 0) return -1;
            }
        }
    }
    var start: usize = 0;
    for (1..n) |i| {
        if (less(points[i], points[start])) start = i;
    }
    var guess = @min(n, 4);
    while (true) {
        var hulls: [32]usize = undefined;
        var offsets: [32]usize = undefined;
        var sizes: [32]usize = undefined;
        var group_of: [32]usize = undefined;
        var position: [32]usize = @splat(32);
        var groups: usize = 0;
        var stored: usize = 0;
        var begin: usize = 0;
        while (begin < n) {
            const end = @min(n, begin+guess);
            offsets[groups] = stored;
            sizes[groups] = groupHull(&points, begin, end-begin, hulls[stored..]);
            for (begin..end) |i| group_of[i] = groups;
            for (0..sizes[groups]) |i| position[hulls[stored+i]] = i;
            stored += sizes[groups]; groups += 1; begin = end;
        }
        var result: [32]usize = undefined;
        result[0] = start;
        var used: usize = 1;
        for (0..guess) |_| {
            const current = result[used-1];
            var candidate: usize = 32;
            for (0..groups) |g| {
                var local: usize = 32;
                if (g == group_of[current]) {
                    if (position[current] == 32) return -1;
                    if (sizes[g] > 1) local = hulls[offsets[g]+(position[current]+1)%sizes[g]];
                } else {
                    local = tangent(&points, hulls[offsets[g]..][0..sizes[g]], current) orelse return -1;
                }
                if (local != 32 and (candidate == 32 or turn(points[current], points[candidate], points[local]) < 0)) candidate = local;
            }
            if (candidate == 32) return -1;
            if (candidate == start) {
                const bytes = 16*used;
                if (output_opt == null or capacity < bytes) return -2;
                const output = output_opt.?;
                for (0..used) |i| {
                    for (0..2) |axis| {
                        const bits: u64 = @bitCast(points[result[i]][axis]);
                        for (0..8) |b| output[16*i+8*axis+b] = @truncate(bits >> @intCast(8*b));
                    }
                }
                return @intCast(bytes);
            }
            if (used == n) return -1;
            result[used] = candidate; used += 1;
        }
        if (guess == n) return -1;
        guess = @min(n, guess*guess);
    }
}
