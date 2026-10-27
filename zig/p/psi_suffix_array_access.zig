const MAX_INPUT: usize = 67;
const MAX_OUTPUT: usize = 16;

fn putU64(output: [*c]u8, word: usize, value: u64) void {
    for (0..8) |byte| output[word * 8 + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn psi_suffix_array_access(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 5 or length > MAX_INPUT) return -1;
    const n0 = input[0]; const query0 = input[1]; const stride0 = input[2];
    if (n0 < 1 or n0 > 32 or query0 < 0 or query0 >= n0 or stride0 < 1 or stride0 > n0 or length != 3 + 2 * @as(usize, @intCast(n0))) return -1;
    const n: usize = @intCast(n0); const query: usize = @intCast(query0); const stride: usize = @intCast(stride0);
    var destinations = [_]bool{false} ** 32;
    var visited = [_]bool{false} ** 32;
    for (0..n) |i| {
        const next = input[3 + i]; const sample = input[3 + n + i];
        if (next < 0 or next >= n0 or destinations[@intCast(next)] or sample < 0 or sample > n0) return -1;
        destinations[@intCast(next)] = true;
    }
    var anchor: usize = n;
    for (0..n) |i| { if (input[3 + n + i] != 0) { anchor = i; break; } }
    if (anchor == n) return -1;
    const anchor_value = input[3 + n + anchor];
    if (@rem(anchor_value - 1, stride0) != 0) return -1;
    var full_sa = [_]u64{0} ** 32;
    var rank = anchor; var value = anchor_value;
    for (0..n) |_| {
        if (visited[rank]) return -1;
        visited[rank] = true; full_sa[rank] = @intCast(value);
        rank = @intCast(input[3 + rank]);
        value = if (value == n0) 1 else value + 1;
    }
    if (rank != anchor or value != anchor_value) return -1;
    for (0..n) |i| {
        const expected: i64 = if ((full_sa[i] - 1) % @as(u64, @intCast(stride)) == 0) @intCast(full_sa[i]) else 0;
        if (input[3 + n + i] != expected) return -1;
    }
    rank = query; var hops: usize = 0;
    while (input[3 + n + rank] == 0) {
        rank = @intCast(input[3 + rank]); hops += 1;
        if (hops >= stride) return -1;
    }
    var position0 = input[3 + n + rank] - 1 - @as(i64, @intCast(hops));
    position0 = @mod(position0, n0);
    if (output_opt == null or capacity < MAX_OUTPUT) return -2;
    const output = output_opt.?;
    putU64(output, 0, @intCast(position0 + 1)); putU64(output, 1, @intCast(hops));
    return MAX_OUTPUT;
}
