export fn directed_perfect_phylogeny(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 146) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > 12 or m0 < 1 or m0 > 12 or length != 2 + @as(usize, @intCast(n0 * m0))) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    var sets = [_]u16{0} ** 12;
    for (0..n) |row| {
        for (0..m) |col| {
            const bit = input[2 + row * m + col];
            if (bit != 0 and bit != 1) return -1;
            if (bit == 1) sets[col] |= @as(u16, 1) << @intCast(row);
        }
    }
    var feasible: i64 = 1;
    for (0..m) |a| {
        for (a + 1..m) |b| {
            const overlap = sets[a] & sets[b];
            if (overlap != 0 and overlap != sets[a] and overlap != sets[b]) feasible = 0;
        }
    }
    if (output == null or capacity < 8) return -2;
    const bits: u64 = @bitCast(feasible);
    for (0..8) |b| output[b] = @truncate(bits >> @intCast(8 * b));
    return 8;
}
