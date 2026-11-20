// Uncompiled multiword bit-parallel LCS length draft.
export fn bit_parallel_lcs(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 515) return -1;
    const nr = input[0]; const mr = input[1];
    if (nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != @as(usize,@intCast(2+nr+mr))) return -1;
    const n: usize = @intCast(nr); const m: usize = @intCast(mr);
    for (2..length) |i| if (input[i] < 0 or input[i] > 255) { return -1; };
    var masks = [_][4]u64{[_]u64{0} ** 4} ** 256;
    var row = [_]u64{0} ** 4;
    const words = (n+63)/64;
    for (0..n) |i| {
        const symbol: usize = @intCast(input[2+i]);
        masks[symbol][i/64] |= @as(u64,1) << @intCast(i%64);
    }
    for (0..m) |i| {
        const symbol: usize = @intCast(input[2+n+i]);
        var carry: u64 = 1; var borrow: u64 = 0;
        for (0..words) |j| {
            const old = row[j]; const combined = old | masks[symbol][j];
            const shifted = (old << 1) | carry; carry = old >> 63;
            const partial = combined -% shifted;
            const difference = partial -% borrow;
            borrow = if (combined < shifted or partial < borrow) 1 else 0;
            row[j] = combined & (combined ^ difference);
        }
    }
    var result: i64 = 0;
    for (row[0..words]) |word| result += @intCast(@popCount(word));
    return result;
}
