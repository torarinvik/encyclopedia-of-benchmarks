const MAX_ITERATIONS: f64 = 8.0;
const INVALID_RESULT: f64 = -1.0e300;

fn piAfterIterations(iterations: usize) f64 {
    var a: f64 = 1.0;
    var b: f64 = @sqrt(0.5);
    var t: f64 = 0.25;
    var p: f64 = 1.0;
    for (0..iterations) |_| {
        const next_a = (a + b) / 2.0;
        const next_b = @sqrt(a * b);
        const difference = a - next_a;
        const next_t = t - p * difference * difference;
        const next_p = 2.0 * p;
        a = next_a;
        b = next_b;
        t = next_t;
        p = next_p;
    }
    const sum = a + b;
    return sum * sum / (4.0 * t);
}

export fn gauss_legendre(iterations_value: f64) f64 {
    if (!(iterations_value >= 0.0 and iterations_value <= MAX_ITERATIONS)
        or @floor(iterations_value) != iterations_value) return INVALID_RESULT;
    const iterations: usize = @intFromFloat(iterations_value);
    return piAfterIterations(iterations);
}
