const MAX_ITEMS: usize = 12;
const MAX_SAFE: i64 = 9_007_199_254_740_991;

fn put32(out: [*]u8, pos: *usize, value: u32) void {
    var bits = value;
    for (0..4) |_| { out[pos.*] = @truncate(bits); pos.* += 1; bits >>= 8; }
}
fn put64(out: [*]u8, pos: *usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |_| { out[pos.*] = @truncate(bits); pos.* += 1; bits >>= 8; }
}

export fn generate_sub_sets(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_ITEMS + 1) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_ITEMS))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (values[i + 1] < -MAX_SAFE or values[i + 1] > MAX_SAFE) return -1;
    const subsets = @as(usize, 1) << @intCast(n);
    const total_items = if (n == 0) 0 else n * (subsets / 2);
    const needed = 4 + 4 * subsets + 8 * total_items;
    if (output == null or capacity < needed) return -2;
    const out = output.?;
    var pos: usize = 0;
    put32(out, &pos, @intCast(subsets));
    for (0..subsets) |mask| {
        var count: u32 = 0;
        for (0..n) |j| if ((mask & (@as(usize, 1) << @intCast(j))) != 0) { count += 1; };
        put32(out, &pos, count);
        for (0..n) |j| {
            if ((mask & (@as(usize, 1) << @intCast(j))) != 0) put64(out, &pos, values[j + 1]);
        }
    }
    return @intCast(pos);
}
