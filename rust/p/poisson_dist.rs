const MAX_MILLI_VALUE: i64 = 100_000;
const MAX_SUCCESS_COUNT: i64 = 20;
const INVALID_RESULT: f64 = -1.0e300;

fn poisson_factorial(x: f64) -> f64 {
    let mut factorial = x;
    let mut index = x as i64 - 1;
    while index > 0 {
        factorial *= index as f64;
        index -= 1;
    }
    if factorial <= 0.0 { factorial = 1.0; }
    factorial
}

fn poisson_point(mean: f64, successes: i64) -> f64 {
    (mean.powf(successes as f64) * (-mean).exp()) / poisson_factorial(successes as f64)
}

#[no_mangle]
pub unsafe extern "C" fn poisson_dist(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 4 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (operation, first, second, third) = (values[0], values[1], values[2], values[3]);
    if operation == 0 {
        if !(0..=MAX_MILLI_VALUE).contains(&first) || !(1..=MAX_MILLI_VALUE).contains(&second) || third != 0 {
            return INVALID_RESULT;
        }
        return (first as f64 / 1000.0) / (second as f64 / 1000.0);
    }
    if operation == 1 {
        if !(0..=MAX_MILLI_VALUE).contains(&first) || !(0..=MAX_MILLI_VALUE).contains(&second) || third != 0 {
            return INVALID_RESULT;
        }
        return (first as f64 / 1000.0) * (second as f64 / 1000.0);
    }
    if operation == 2 {
        if !(0..=MAX_MILLI_VALUE).contains(&first) || !(0..=MAX_SUCCESS_COUNT).contains(&second) || third != 0 {
            return INVALID_RESULT;
        }
        return poisson_point(first as f64 / 1000.0, second);
    }
    if operation == 3 {
        if !(0..=MAX_MILLI_VALUE).contains(&first) || second < 0 || second > third || third > MAX_SUCCESS_COUNT {
            return INVALID_RESULT;
        }
        let mean = first as f64 / 1000.0;
        let mut probability = 0.0;
        for successes in second..=third {
            probability += poisson_point(mean, successes);
        }
        return probability;
    }
    INVALID_RESULT
}
