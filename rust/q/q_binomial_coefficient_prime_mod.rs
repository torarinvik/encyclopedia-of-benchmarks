const MAX_T: i64 = 16;
const MAX_N: i64 = 16;
const MAX_MODULUS: i64 = 31;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 36;

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

fn modular_power(base_value: i64, exponent_value: usize, modulus: i64) -> i64 {
    let (mut base, mut exponent, mut result) = (base_value, exponent_value, 1_i64);
    while exponent > 0 {
        if (exponent & 1) != 0 {
            result = result * base % modulus;
        }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn q_binomial_coefficient_prime_mod(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let count_value = *input;
    let modulus = *input.add(1);
    let q_value = *input.add(2);
    if count_value < 1
        || count_value > MAX_T
        || modulus < 2
        || modulus > MAX_MODULUS
        || !is_prime(modulus)
        || q_value < 0
        || q_value >= modulus
    {
        return -1;
    }
    let count = count_value as usize;
    if length != 3 + 2 * count {
        return -1;
    }

    let mut max_n = 0_usize;
    for query in 0..count {
        let n_value = *input.add(3 + 2 * query);
        let k_value = *input.add(4 + 2 * query);
        if n_value < 0
            || n_value > MAX_N
            || k_value < 0
            || k_value > MAX_N
            || n_value >= modulus
            || k_value >= modulus
        {
            return -1;
        }
        max_n = max_n.max(n_value as usize);
    }
    if output.is_null() || capacity < count {
        return -2;
    }

    let mut table = [[0_i64; 17]; 17];
    table[0][0] = 1;
    for n in 1..=max_n {
        table[n][0] = 1;
        for k in 1..=n {
            let previous_same = if k < n { table[n - 1][k] } else { 0 };
            let weight = modular_power(q_value, n - k, modulus);
            table[n][k] =
                (previous_same + weight * table[n - 1][k - 1]) % modulus;
        }
    }
    for query in 0..count {
        let n = *input.add(3 + 2 * query) as usize;
        let k = *input.add(4 + 2 * query) as usize;
        *output.add(query) = if k > n { 0 } else { table[n][k] as u8 };
    }
    count as i64
}
