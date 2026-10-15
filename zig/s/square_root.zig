/// Newton square root using binary64 arithmetic and a portable initial estimate.
export fn square_root(value: f64) f64 {
    if (value == 0.0) return 0.0;
    var estimate: f64 = if (value >= 1.0) value else 1.0;
    for (0..1100) |_| {
        const next = 0.5 * estimate + 0.5 * (value / estimate);
        if (next >= estimate) return estimate;
        estimate = next;
    }
    return estimate;
}
