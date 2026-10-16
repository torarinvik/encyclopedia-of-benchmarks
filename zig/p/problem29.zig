/// Count distinct powers using maximal perfect-power roots.
export fn problem29(limit: i64) i64 {
    if (limit < 1 or limit > 100) return -1;
    if (limit == 1) return 0;
    var roots: [101]i64 = undefined;
    var exponents: [101]i64 = undefined;
    var seen: [60701]bool = @splat(false);
    var distinct: i64 = 0;
    var a: i64 = 2;
    while (a <= limit) : (a += 1) {
        roots[@intCast(a)] = a;
        exponents[@intCast(a)] = 1;
        var candidate_exponent: i64 = 2;
        while (candidate_exponent <= 6) : (candidate_exponent += 1) {
            var candidate_root: i64 = 2;
            while (candidate_root <= a) : (candidate_root += 1) {
                var power: i64 = 1;
                var step: i64 = 0;
                while (step < candidate_exponent) : (step += 1) {
                    power *= candidate_root;
                    if (power > a) break;
                }
                if (power == a and candidate_exponent > exponents[@intCast(a)]) {
                    roots[@intCast(a)] = candidate_root;
                    exponents[@intCast(a)] = candidate_exponent;
                }
            }
        }
        var b: i64 = 2;
        while (b <= limit) : (b += 1) {
            const key: usize = @intCast(roots[@intCast(a)] * 601 + exponents[@intCast(a)] * b);
            if (!seen[key]) { seen[key] = true; distinct += 1; }
        }
    }
    return distinct;
}
