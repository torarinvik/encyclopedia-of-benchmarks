const MAX_COORDINATE: i64 = 10_000;

fn rational_prime(value: i64) -> bool {
    if value < 2 { return false; }
    if value % 2 == 0 { return value == 2; }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn gaussian_prime_classifier(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 3 { return -1; }
    if length != 2 { return -1; }
    let real = unsafe { *input };
    let imaginary = unsafe { *input.add(1) };
    if real < -MAX_COORDINATE || real > MAX_COORDINATE ||
        imaginary < -MAX_COORDINATE || imaginary > MAX_COORDINATE { return -1; }
    if real == 0 && imaginary == 0 { return 0; }
    if real == 0 || imaginary == 0 {
        let axis = if real == 0 { imaginary } else { real };
        let rational = if axis < 0 { -axis } else { axis };
        return if rational % 4 == 3 && rational_prime(rational) { 1 } else { 0 };
    }
    let norm = real * real + imaginary * imaginary;
    if rational_prime(norm) { 1 } else { 0 }
}
