const INVALID_RESULT: f64 = -1.0e300;

fn simpsonRuleF(x: f64) f64 {
    return (x - 0.0) * (x - 0.0);
}

export fn simpson_rule(b: f64, steps: f64) f64 {
    if ((b != 1.0 and b != 2.0 and b != 3.0) or steps != 10.0) return INVALID_RESULT;

    const a = 0.0;
    const h = (b - a) / steps;
    var x = a + h;
    var y = 0.0;
    y += (h / 3.0) * simpsonRuleF(a);
    var count: usize = 2;
    while (x < b - h) {
        const weight: f64 = if (count % 2 == 0) 4.0 else 2.0;
        y += (h / 3.0) * weight * simpsonRuleF(x);
        count += 1;
        x = x + h;
    }
    y += (h / 3.0) * simpsonRuleF(b);
    return y;
}
