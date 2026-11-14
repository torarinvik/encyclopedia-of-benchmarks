// Uncompiled exact-length walk counting draft.
export fn fixed_length_walk_count(input: [*c]const i64, length: usize) i64 {
    const modulus: i64 = 1_000_000_007;
    if (input == null or length < 4 or length > 261) return -1;
    const nv = input[0]; var k = input[1];
    const source = input[2]; const target = input[3];
    if (nv < 1 or nv > 16 or k < 0 or k > 1_000_000_000 or source < 0 or source >= nv or
        target < 0 or target >= nv or length != 4 + @as(usize, @intCast(nv*nv))) return -1;
    const n: usize = @intCast(nv);
    var matrix = [_][16]i64{[_]i64{0} ** 16} ** 16;
    var vector = [_]i64{0} ** 16;
    for (0..n) |i| for (0..n) |j| {
        const value = input[4+i*n+j];
        if (value < 0 or value > 100) return -1;
        matrix[i][j] = value;
    };
    vector[@intCast(source)] = 1;
    while (k > 0) {
        if ((k & 1) != 0) {
            var next = [_]i64{0} ** 16;
            for (0..n) |i| for (0..n) |j|
                next[j] = @mod(next[j] + vector[i]*matrix[i][j], modulus);
            vector = next;
        }
        k >>= 1;
        if (k > 0) {
            var next = [_][16]i64{[_]i64{0} ** 16} ** 16;
            for (0..n) |i| for (0..n) |p| for (0..n) |j|
                next[i][j] = @mod(next[i][j] + matrix[i][p]*matrix[p][j], modulus);
            matrix = next;
        }
    }
    return vector[@intCast(target)];
}
