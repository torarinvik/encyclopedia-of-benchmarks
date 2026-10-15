module sqrt_double;

// Bisection square root matching the pinned C++ update and stopping rule.
fn double sqrt_double_bisect(double value)
{
    if (value > 0.0 && value < 1.0) {
        return 1.0 / sqrt_double_bisect(1.0 / value);
    }

    double low = 0.0;
    double high = value;
    while (low <= high) {
        double mid = (low + high) / 2.0;
        if (mid * mid > value) {
            high = mid;
        } else {
            if (value - mid * mid < 1e-12) return mid;
            low = mid;
        }
    }
    return -1.0;
}

fn double sqrt_double(double value) @export("sqrt_double")
{
    if (value == 0.0) return 0.0;
    if (value < 1.0 / 256.0 || value > 64.0) return -1.0;
    return sqrt_double_bisect(value);
}
