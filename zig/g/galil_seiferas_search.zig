const MAX_INPUT: usize = 162;

export fn galil_seiferas_search(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 2 or length > MAX_INPUT) return -2;
    const values = values_opt.?;
    if (values[0] < 0 or values[0] > 128 or values[1] < 1 or values[1] > 32) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (0..n + m) |i| {
        if (values[2 + i] < 0 or values[2 + i] > 15) return -2;
    }
    if (m > n) return 0;
    const pattern_start = 2 + n;
    var s: usize = 0;
    var p1: usize = 1;
    var q1: usize = 0;
    var factorized = false;
    while (true) {
        while (s + p1 + q1 < m and values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1]) : (q1 += 1) {}
        if (p1 + q1 >= 4 * p1) {
            var p2 = q1;
            var q2: usize = 0;
            while (true) {
                while (p2 + q2 < 4 * p2 and s + p2 + q2 < m and
                    values[pattern_start + s + q2] == values[pattern_start + s + p2 + q2]) : (q2 += 1) {}
                if (p2 + q2 == 4 * p2) {
                    while (true) {
                        while (s + p1 + q1 < m and values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1]) : (q1 += 1) {}
                        while (p1 + q1 >= 4 * p1) { s += p1; q1 -= p1; }
                        if (s + p1 + q1 == m) { factorized = true; break; }
                        p1 += q1 / 4 + 1;
                        q1 = 0;
                        if (p1 >= p2) break;
                    }
                    break;
                }
                if (s + p2 + q2 == m) { factorized = true; break; }
                if (q2 == p1 + q1) { p2 += p1; q2 -= p1; }
                else { p2 += q2 / 4 + 1; q2 = 0; }
            }
            if (factorized or s + p1 + q1 == m) break;
        } else {
            if (s + p1 + q1 == m) break;
            p1 += q1 / 4 + 1;
            q1 = 0;
        }
    }
    var p: usize = 0;
    var q: usize = 0;
    var matches: i64 = 0;
    while (p <= n - m) {
        while (s + q < m and values[pattern_start + s + q] == values[2 + p + s + q]) : (q += 1) {}
        if (q == m - s) {
            var i: usize = 0;
            while (i < s and values[pattern_start + i] == values[2 + p + i]) : (i += 1) {}
            if (i == s) matches += 1;
        }
        if (q == p1 + q1) { p += p1; q -= p1; }
        else { p += q / 4 + 1; q = 0; }
    }
    return matches;
}
