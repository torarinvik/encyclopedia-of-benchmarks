const max_n: usize = 128;
const max_q: usize = 32;

fn lower_bound(tails: *const [max_n]i64, count: usize, value: i64) usize {
    var lo: usize = 0;
    var hi = count;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (tails[mid] < value) { lo = mid + 1; } else { hi = mid; }
    }
    return lo;
}
fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> (8 * byte));
}

export fn static_range_lis_query(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 195) return -1;
    const input = input_opt.?;
    const nv = input[0];
    const qv = input[1];
    if (nv < 1 or nv > 128 or qv < 1 or qv > 32) return -1;
    const n: usize = @intCast(nv);
    const q: usize = @intCast(qv);
    if (length != 2 + n + 2 * q) return -1;
    var permutation = [_]i64{0} ** max_n;
    var seen = [_]bool{false} ** max_n;
    var left = [_]i64{0} ** max_q;
    var right = [_]i64{0} ** max_q;
    var answers = [_]i64{0} ** max_q;
    var tails = [_]i64{0} ** max_n;
    for (0..n) |i| {
        const value = input[2 + i];
        if (value < 0 or value >= nv or seen[@intCast(value)]) return -1;
        seen[@intCast(value)] = true;
        permutation[i] = value;
    }
    var off: usize = 2 + n;
    for (0..q) |k| {
        left[k] = input[off];
        right[k] = input[off + 1];
        off += 2;
        if (left[k] < 0 or left[k] > right[k] or right[k] > nv) return -1;
    }
    for (0..q) |k| {
        var count: usize = 0;
        const range_left: usize = @intCast(left[k]);
        const range_right: usize = @intCast(right[k]);
        for (range_left..range_right) |i| {
            const at = lower_bound(&tails, count, permutation[i]);
            tails[at] = permutation[i];
            if (at == count) count += 1;
        }
        answers[k] = @intCast(count);
    }
    const bytes = 8 * q;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..q) |k| put_i64_le(output, 8 * k, answers[k]);
    return @intCast(bytes);
}
