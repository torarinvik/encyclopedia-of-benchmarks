const SIDE_LIMIT: f64 = 1_000_000.0;

export fn herons_formula(a: f64, b: f64, c: f64) f64 {
    if (a < 1.0 or a > SIDE_LIMIT or @floor(a) != a or
        b < 1.0 or b > SIDE_LIMIT or @floor(b) != b or
        c < 1.0 or c > SIDE_LIMIT or @floor(c) != c or
        a + b <= c or b + c <= a or c + a <= b) return -1.0;

    const s = (a + b + c) / 2.0;
    return @sqrt((s) * (s - a) * (s - b) * (s - c));
}

