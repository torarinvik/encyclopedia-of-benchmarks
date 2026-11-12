const MODULUS: i64 = 998_244_353;
const MAX_N: i64 = 16;

#[no_mangle]
pub unsafe extern "C" fn stirling_number_of_the_second_kind(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_N {
        return -1;
    }
    let n = n_value as usize;

    let mut row = [0_i64; 17];
    row[0] = 1;
    let mut current_n = 1;
    while current_n <= n {
        let mut k = current_n;
        while k > 0 {
            row[k] = (row[k - 1] + k as i64 * row[k]) % MODULUS;
            k -= 1;
        }
        row[0] = 0;
        current_n += 1;
    }

    let mut result = 0_i64;
    for k in 0..=n {
        let next = (k + 1) as i64;
        let weight = next * next * next;
        result = (result + weight * row[k]) % MODULUS;
    }
    result
}
