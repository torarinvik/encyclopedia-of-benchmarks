const MAX_ITEMS: usize = 12;

fn put32(out: [*]u8, pos: *usize, value: u32) void {
    var bits = value;
    for (0..4) |_| { out[pos.*] = @truncate(bits); pos.* += 1; bits >>= 8; }
}

fn emitSubsets(input: [*]const i64, n: usize, index: usize, mask: usize,
               selected: u32, out: [*]u8, pos: *usize) void {
    if (index == n) {
        put32(out, pos, selected);
        for (0..n) |i| {
            if ((mask & (@as(usize, 1) << @intCast(i))) != 0) { out[pos.*] = @intCast(input[i + 1]); pos.* += 1; }
        }
        return;
    }
    emitSubsets(input, n, index + 1, mask | (@as(usize, 1) << @intCast(index)), selected + 1, out, pos);
    emitSubsets(input, n, index + 1, mask, selected, out, pos);
}

export fn generate_subsets_recursive(input: ?[*]const i64, length: usize,
                                     output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_ITEMS + 1) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_ITEMS))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (values[i + 1] < 0 or values[i + 1] > 127) return -1;
    const subsets = @as(usize, 1) << @intCast(n);
    const needed = 4 + 4 * subsets + n * (subsets / 2);
    if (output == null or capacity < needed) return -2;
    const out = output.?;
    var pos: usize = 0;
    put32(out, &pos, @intCast(subsets));
    emitSubsets(values, n, 0, 0, 0, out, &pos);
    return @intCast(pos);
}
