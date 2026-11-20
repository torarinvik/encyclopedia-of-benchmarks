const max_len: usize = 32;
const max_blocks: usize = 16;
const max_bytes: usize = 912;
const max_input: usize = 68;

const Match = struct { source: usize, target: usize, length: usize };
const Bounds = struct { first: usize, last: usize };

fn blockHash(data: []const i64, start: usize, width: usize) i64 {
    var value: i64 = 0;
    for (0..width) |i| value = value * 257 + data[start + i] + 1;
    return value;
}
fn suffixCmp(h: []const i64, a0: usize, b0: usize) i32 {
    var a = a0; var b = b0;
    while (a < h.len and b < h.len) {
        if (h[a] != h[b]) return if (h[a] < h[b]) -1 else 1;
        a += 1; b += 1;
    }
    if (a == h.len and b == h.len) return 0;
    return if (a == h.len) -1 else 1;
}
fn prefixCmp(h: []const i64, suffix: usize, q: []const i64, depth: usize) i32 {
    for (0..depth) |i| {
        if (suffix + i >= h.len) return -1;
        if (h[suffix + i] != q[i]) return if (h[suffix + i] < q[i]) -1 else 1;
    }
    return 0;
}
fn interval(sa: []const usize, h: []const i64, q: []const i64, depth: usize) Bounds {
    var lo: usize = 0; var hi = sa.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (prefixCmp(h, sa[mid], q, depth) < 0) lo = mid + 1 else hi = mid;
    }
    const first = lo; hi = sa.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (prefixCmp(h, sa[mid], q, depth) <= 0) lo = mid + 1 else hi = mid;
    }
    return .{ .first = first, .last = lo };
}
fn bestDepth(sa: []const usize, h: []const i64, q: []const i64) usize {
    var lo: usize = 0; var hi = @min(sa.len, q.len) + 1;
    while (lo + 1 < hi) {
        const mid = lo + (hi - lo) / 2;
        const bounds = interval(sa, h, q, mid);
        if (bounds.first < bounds.last) lo = mid else hi = mid;
    }
    return lo;
}
fn extendMatch(ref: []const i64, ver: []const i64, source0: usize, target0: usize, floor: usize) Match {
    var source = source0; var target = target0; var length: usize = 0;
    while (source + length < ref.len and target + length < ver.len and ref[source + length] == ver[target + length]) length += 1;
    while (source > 0 and target > floor and ref[source - 1] == ver[target - 1]) { source -= 1; target -= 1; length += 1; }
    return .{ .source = source, .target = target, .length = length };
}
fn better(a: Match, b: Match) bool {
    return a.length > b.length or (a.length == b.length and (a.target < b.target or (a.target == b.target and a.source < b.source)));
}
fn findAt(ref: []const i64, ver: []const i64, p: usize, sa: []const usize,
          hashes: []const i64, target: usize, floor: usize) ?Match {
    const qcount = (ver.len - target) / p;
    if (qcount == 0 or sa.len == 0) return null;
    var query = [_]i64{0} ** max_blocks;
    for (0..qcount) |i| query[i] = blockHash(ver, target + i * p, p);
    const query_slice = query[0..qcount];
    const depth = bestDepth(sa, hashes, query_slice);
    if (depth == 0) return null;
    const bounds = interval(sa, hashes, query_slice, @max(1, depth - 1));
    var best: ?Match = null;
    for (bounds.first..bounds.last) |rank| {
        const source = sa[rank] * p;
        if (source + p > ref.len) continue;
        const candidate = extendMatch(ref, ver, source, target, floor);
        if (candidate.length < p) continue;
        if (best == null or better(candidate, best.?)) best = candidate;
    }
    return best;
}
fn storeI64(out: *[max_bytes]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn hsadelta_differential_compression(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > max_input) return -1;
    const words = input.?;
    const mv = words[0]; const nv = words[1]; const pv = words[2];
    if (mv < 0 or mv > @as(i64, @intCast(max_len)) or
        nv < 0 or nv > @as(i64, @intCast(max_len)) or pv < 2 or pv > 4) return -1;
    const m: usize = @intCast(mv); const n: usize = @intCast(nv); const p: usize = @intCast(pv);
    if (length != 3 + m + n) return -1;
    var ref_storage = [_]i64{0} ** max_len;
    var ver_storage = [_]i64{0} ** max_len;
    for (0..m) |i| { if (words[3+i] < 0 or words[3+i] > 255) return -1; ref_storage[i] = words[3+i]; }
    for (0..n) |i| { if (words[3+m+i] < 0 or words[3+m+i] > 255) return -1; ver_storage[i] = words[3+m+i]; }
    const ref = ref_storage[0..m]; const ver = ver_storage[0..n];

    const block_count = if (m >= p) (m-p)/p+1 else 0;
    var hash_storage = [_]i64{0} ** max_blocks;
    var sa_storage = [_]usize{0} ** max_blocks;
    for (0..block_count) |i| { hash_storage[i] = blockHash(ref, i*p, p); sa_storage[i] = i; }
    const hashes = hash_storage[0..block_count]; const sa = sa_storage[0..block_count];
    if (block_count > 1) {
        for (1..block_count) |i| {
            const value = sa_storage[i]; var j = i;
            while (j > 0 and (suffixCmp(hashes, value, sa_storage[j-1]) < 0 or
                (suffixCmp(hashes, value, sa_storage[j-1]) == 0 and value < sa_storage[j-1]))) { sa_storage[j] = sa_storage[j-1]; j -= 1; }
            sa_storage[j] = value;
        }
    }

    var staged = [_]u8{0} ** max_bytes;
    var count: usize = 0;
    var cursor: usize = 0; var consumed: usize = 0;
    while (cursor + p <= n) {
        var best: ?Match = null;
        const scan_end = @min(cursor + p - 1, n - p);
        for (cursor..scan_end+1) |target| {
            if (findAt(ref,ver,p,sa,hashes,target,consumed)) |candidate| {
                if (best == null or better(candidate,best.?)) best = candidate;
            }
        }
        if (best) |match| {
            if (match.target > consumed) {
                storeI64(&staged, 8 * count, 0); count += 1;
                storeI64(&staged, 8 * count, @intCast(match.target-consumed)); count += 1;
                for (consumed..match.target) |i| { storeI64(&staged, 8 * count, ver[i]); count += 1; }
            }
            storeI64(&staged, 8 * count, 1); count += 1;
            storeI64(&staged, 8 * count, @intCast(match.source)); count += 1;
            storeI64(&staged, 8 * count, @intCast(match.length)); count += 1;
            consumed = match.target + match.length; cursor = consumed;
        } else cursor += 1;
    }
    if (consumed < n) {
        storeI64(&staged, 8 * count, 0); count += 1;
        storeI64(&staged, 8 * count, @intCast(n-consumed)); count += 1;
        for (consumed..n) |i| { storeI64(&staged, 8 * count, ver[i]); count += 1; }
    }
    const required = count * 8;
    if (required > 0 and (output == null or capacity < required)) return -2;
    if (required > 0) { const destination = output.?; for (0..required) |i| destination[i] = staged[i]; }
    return @intCast(required);
}
