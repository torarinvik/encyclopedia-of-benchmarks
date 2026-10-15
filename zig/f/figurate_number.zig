/// Pack triangular, tetrahedral, and pentatope membership bits.
fn is_triangular(n: i64) bool {
    var i: i64 = 0;
    while (i <= n) : (i += 1) {
        const term = @divTrunc(i * (i + 1), 2);
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

fn is_tetrahedral(n: i64) bool {
    var i: i64 = 1;
    while (i <= n) : (i += 1) {
        const term = @divTrunc(i * (i + 1) * (i + 2), 6);
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

fn is_pentatope(n: i64) bool {
    var i: i64 = 1;
    while (i <= n) : (i += 1) {
        const term = @divTrunc(i * (i + 1) * (i + 2) * (i + 3), 24);
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

export fn figurate_number(n: i64) i64 {
    if (n < 0 or n > 1_000_000) return -1;
    return (if (is_triangular(n)) @as(i64, 1) else 0)
        + (if (is_tetrahedral(n)) @as(i64, 2) else 0)
        + (if (is_pentatope(n)) @as(i64, 4) else 0);
}
