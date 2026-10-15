const INVALID_RESULT: f64 = -1.0e300;

/// Operation 0 tests a geometric sequence; operation 1 computes its mean.
#[no_mangle]
pub extern "C" fn geometric(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 { return INVALID_RESULT; }
    let operation = unsafe { *values };
    let count = length - 1;
    if operation == 0 {
        if count > 16 { return INVALID_RESULT; }
        for index in 1..length {
            let value = unsafe { *values.add(index) };
            if !(-100..=100).contains(&value) { return INVALID_RESULT; }
        }
        if count == 1 { return 1.0; }
        let first = unsafe { *values.add(1) };
        if first == 0 { return 0.0; }
        let common_ratio = unsafe { *values.add(2) } as f64 / first as f64;
        for index in 0..count - 1 {
            let current = unsafe { *values.add(index + 1) };
            if current == 0 { return 0.0; }
            let next = unsafe { *values.add(index + 2) };
            if next as f64 / current as f64 != common_ratio { return 0.0; }
        }
        return 1.0;
    }
    if operation == 1 {
        if count > 7 { return INVALID_RESULT; }
        let mut product = 1_i64;
        for index in 1..length {
            let value = unsafe { *values.add(index) };
            if !(0..=100).contains(&value) { return INVALID_RESULT; }
            product *= value;
        }
        return (product as f64).powf(1.0 / count as f64);
    }
    INVALID_RESULT
}
