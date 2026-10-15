/// Bisection square root matching the pinned C++ update and stopping rule.
fn sqrt_double_bisect(value: f64) -> f64 {
    if value > 0.0 && value < 1.0 {
        return 1.0 / sqrt_double_bisect(1.0 / value);
    }

    let mut low = 0.0;
    let mut high = value;
    while low <= high {
        let mid = (low + high) / 2.0;
        if mid * mid > value {
            high = mid;
        } else {
            if value - mid * mid < 1e-12 {
                return mid;
            }
            low = mid;
        }
    }
    -1.0
}

#[no_mangle]
pub extern "C" fn sqrt_double(value: f64) -> f64 {
    if value == 0.0 {
        return 0.0;
    }
    if value < 1.0 / 256.0 || value > 64.0 {
        return -1.0;
    }
    sqrt_double_bisect(value)
}
