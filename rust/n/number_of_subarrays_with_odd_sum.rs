/// Count subarrays with an odd sum, modulo 1,000,000,007.
#[no_mangle]
pub extern "C" fn number_of_subarrays_with_odd_sum(values: *const i64, length: usize) -> i64 {
    const MODULUS: i64 = 1_000_000_007;
    if length > 100_000 {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut even_prefixes = 1i64;
    let mut odd_prefixes = 0i64;
    let mut result = 0i64;
    let mut parity = 0i64;
    for &value in values {
        if i32::try_from(value).is_err() {
            return -1;
        }
        if value % 2 != 0 {
            parity = 1 - parity;
        }
        if parity == 0 {
            result = (result + odd_prefixes) % MODULUS;
            even_prefixes += 1;
        } else {
            result = (result + even_prefixes) % MODULUS;
            odd_prefixes += 1;
        }
    }
    result
}
