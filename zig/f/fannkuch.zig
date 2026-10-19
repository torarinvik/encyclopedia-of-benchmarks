// Bounded port of the Benchmark Game fannkuch counter traversal.
export fn fannkuch(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 1) return -1;
    const n64 = values[0];
    if (n64 < 1 or n64 > 8) return -1;
    const n: usize = @intCast(n64);
    var perm = [_]i64{0} ** 8;
    var perm1 = [_]i64{0} ** 8;
    var count = [_]i64{0} ** 8;
    for (0..n) |i| perm1[i] = @intCast(i);
    var r = n;
    var flips_max: i64 = 0;
    while (true) {
        while (r != 1) { count[r - 1] = @intCast(r); r -= 1; }
        if (perm1[0] != 0 and perm1[n - 1] != @as(i64, @intCast(n - 1))) {
            for (1..n) |i| perm[i] = perm1[i];
            var k: usize = @intCast(perm1[0]);
            var flips: i64 = 0;
            while (true) {
                var i: usize = 1;
                var j = k - 1;
                while (i < j) : (i += 1) { const tmp = perm[i]; perm[i] = perm[j]; perm[j] = tmp; j -= 1; }
                flips += 1;
                j = @intCast(perm[k]);
                perm[k] = @intCast(k);
                k = j;
                if (k == 0) break;
            }
            if (flips_max < flips) flips_max = flips;
        }
        while (true) {
            if (r == n) return flips_max;
            const first = perm1[0];
            for (0..r) |i| perm1[i] = perm1[i + 1];
            perm1[r] = first;
            count[r] -= 1;
            if (count[r] > 0) break;
            r += 1;
        }
    }
}
