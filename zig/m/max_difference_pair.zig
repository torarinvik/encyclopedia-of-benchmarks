/// Recursive maximum-difference pair with the pinned source's tie order.
const Pair = struct { small: i64, big: i64 };
fn solve(values: []const i64) Pair {
    if (values.len == 1) return .{ .small = values[0], .big = values[0] };
    const left_n = values.len / 2;
    const left = solve(values[0..left_n]);
    const right = solve(values[left_n..]);
    var min_left = values[0]; var max_right = values[left_n];
    for (values[1..left_n]) |v| { if (v < min_left) min_left = v; }
    for (values[left_n + 1 ..]) |v| { if (v > max_right) max_right = v; }
    const cross = max_right - min_left;
    const right_diff = right.big - right.small; const left_diff = left.big - left.small;
    if (right_diff > cross and right_diff > left_diff) return right;
    if (left_diff > cross) return left;
    return .{ .small = min_left, .big = max_right };
}
fn putLe(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at + b] = @truncate(bits >> @intCast(8 * b));
}
pub export fn max_difference_pair(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const n64 = input[0]; if (n64 < 1 or n64 > 128) return -1;
    const n: usize = @intCast(n64); if (length != n + 1) return -1;
    const values = input[1..][0..n];
    for (values) |v| { if (v < -1_000_000 or v > 1_000_000) return -1; }
    if (output == null or capacity < 16) return -2;
    const result = solve(values);
    putLe(output, 0, result.small); putLe(output, 8, result.big);
    return 16;
}
