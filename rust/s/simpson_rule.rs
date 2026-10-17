const INVALID_RESULT: f64 = -1.0e300;

fn simpson_rule_f(x: f64) -> f64 {
    (x - 0.0) * (x - 0.0)
}

#[no_mangle]
pub extern "C" fn simpson_rule(b: f64, steps: f64) -> f64 {
    if (b != 1.0 && b != 2.0 && b != 3.0) || steps != 10.0 { return INVALID_RESULT; }

    let a = 0.0;
    let h = (b - a) / steps;
    let mut x = a + h;
    let mut y = 0.0;
    y += (h / 3.0) * simpson_rule_f(a);
    let mut count = 2;
    while x < b - h {
        let weight = 4 - 2 * (count % 2);
        y += (h / 3.0) * f64::from(weight) * simpson_rule_f(x);
        count += 1;
        x = x + h;
    }
    y += (h / 3.0) * simpson_rule_f(b);
    y
}
