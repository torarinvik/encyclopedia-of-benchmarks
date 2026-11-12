const MAX_N: i64 = 1_000_000_000_000_000_000;
const MAX_T: usize = 8;
const MAX_K: i64 = 8;
const WIDTH: usize = 9;

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn stirling_value(n: i64, k: usize, modulus: i64) -> i64 {
    let quotient = n / modulus;
    let remainder = n % modulus;
    if quotient > k as i64 {
        return 0;
    }
    let target = k - quotient as usize;
    let mut coefficients = [0_i64; WIDTH];
    coefficients[0] = 1;
    for residue in 0..remainder {
        let mut degree = target;
        while degree > 0 {
            coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus;
            if coefficients[degree] < 0 {
                coefficients[degree] += modulus;
            }
            degree -= 1;
        }
        coefficients[0] = (-residue * coefficients[0]) % modulus;
        if coefficients[0] < 0 {
            coefficients[0] += modulus;
        }
    }
    let coefficient = coefficients[target];
    if quotient % 2 == 0 || coefficient == 0 {
        coefficient
    } else {
        modulus - coefficient
    }
}

#[no_mangle]
pub unsafe extern "C" fn stirling_number_of_the_first_kind_small_p_large_n(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 2 + 2 * MAX_T {
        return -1;
    }
    let count_value = *input;
    let modulus = *input.add(1);
    if count_value < 1 || count_value > MAX_T as i64
        || length != (2 + 2 * count_value) as usize
        || modulus < 11 || modulus > 97 || !is_prime(modulus)
    {
        return -1;
    }

    let mut result = 0_i64;
    for case_index in 0..count_value as usize {
        let n = *input.add(2 + 2 * case_index);
        let k_value = *input.add(3 + 2 * case_index);
        if n < 0 || n > MAX_N || k_value < 0 || k_value > MAX_K || k_value > n {
            return -1;
        }
        let value = stirling_value(n, k_value as usize, modulus);
        let next = (case_index + 1) as i64;
        result = (result + next * next * value) % modulus;
    }
    result
}
