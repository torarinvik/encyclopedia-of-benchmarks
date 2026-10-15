const SIDE_LIMIT: f64 = 1_000_000.0;

#[no_mangle]
pub extern "C" fn herons_formula(a: f64, b: f64, c: f64) -> f64 {
    if a < 1.0 || a > SIDE_LIMIT || a.floor() != a ||
        b < 1.0 || b > SIDE_LIMIT || b.floor() != b ||
        c < 1.0 || c > SIDE_LIMIT || c.floor() != c ||
        a + b <= c || b + c <= a || c + a <= b { return -1.0; }

    let s = (a + b + c) / 2.0;
    (s * (s - a) * (s - b) * (s - c)).sqrt()
}

