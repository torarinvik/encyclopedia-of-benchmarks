/// Bisection square root matching the pinned C++ update and stopping rule.
fn sqrtDoubleBisect(value: f64) f64 {
    if (value > 0.0 and value < 1.0) {
        return 1.0 / sqrtDoubleBisect(1.0 / value);
    }

    var low: f64 = 0.0;
    var high: f64 = value;
    while (low <= high) {
        const mid = (low + high) / 2.0;
        if (mid * mid > value) {
            high = mid;
        } else {
            if (value - mid * mid < 1e-12) return mid;
            low = mid;
        }
    }
    return -1.0;
}

/// Return the bisection square root for the shared bounded binary64 domain.
export fn sqrt_double(value: f64) f64 {
    if (value == 0.0) return 0.0;
    if (value < 1.0 / 256.0 or value > 64.0) return -1.0;
    return sqrtDoubleBisect(value);
}
