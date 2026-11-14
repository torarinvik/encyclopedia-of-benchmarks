// Uncompiled exact-length shortest-walk draft.
export fn fixed_length_walk_minplus(input: [*c]const i64, length: usize) i64 {
    const inf: i64 = 1_000_000_000_000_000;
    if (input == null or length < 4 or length > 261) return -100_000_002;
    const nv = input[0];
    var k = input[1];
    const source = input[2];
    const target = input[3];
    if (nv < 1 or nv > 16 or k < 0 or k > 1_000_000 or source < 0 or source >= nv or
        target < 0 or target >= nv or length != 4 + @as(usize, @intCast(nv * nv))) return -100_000_002;
    const n: usize = @intCast(nv);
    var matrix = [_][16]i64{[_]i64{inf} ** 16} ** 16;
    var distance = [_]i64{inf} ** 16;
    distance[@intCast(source)] = 0;
    for (0..n) |i| for (0..n) |j| {
        const weight = input[4+i*n+j];
        if (weight != 1_000_000 and (weight < -100 or weight > 100)) return -100_000_002;
        matrix[i][j] = if (weight == 1_000_000) inf else weight;
    };
    while (k > 0) {
        if ((k & 1) != 0) {
            var next = [_]i64{inf} ** 16;
            for (0..n) |i| for (0..n) |j| {
                if (distance[i] != inf and matrix[i][j] != inf)
                    next[j] = @min(next[j], distance[i] + matrix[i][j]);
            };
            distance = next;
        }
        k >>= 1;
        if (k > 0) {
            var next = [_][16]i64{[_]i64{inf} ** 16} ** 16;
            for (0..n) |i| for (0..n) |p| for (0..n) |j| {
                if (matrix[i][p] != inf and matrix[p][j] != inf)
                    next[i][j] = @min(next[i][j], matrix[i][p] + matrix[p][j]);
            };
            matrix = next;
        }
    }
    const result = distance[@intCast(target)];
    return if (result == inf) -100_000_001 else result;
}
