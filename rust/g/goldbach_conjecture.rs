/// Return the first source-ordered Goldbach pair as two little-endian i32 values.
fn goldbach_prime(value: i64) -> bool {
    if value == 2 { return true; }
    if value < 2 || value % 2 == 0 { return false; }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn goldbach_conjecture(number: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if number < 4 || number > 4096 || number % 2 != 0 { return -1; }
    if output.is_null() || output_capacity < 8 { return -2; }
    let mut first = 0i64;
    while first <= number / 2 {
        let second = number - first;
        if goldbach_prime(first) && goldbach_prime(second) {
            let pair = [first as u32, second as u32];
            for j in 0..2 {
                for b in 0..4 {
                    *output.add(4 * j + b) = ((pair[j] >> (8 * b)) & 0xff) as u8;
                }
            }
            return 8;
        }
        first += 1;
    }
    -1
}
