const MODULUS: i64 = 998_244_353;
const MAX_NODES: usize = 8;
const MAX_INPUT_LENGTH: usize = 12;

fn mod_norm(value: i64) -> i64 {
    let reduced = value % MODULUS;
    if reduced < 0 { reduced + MODULUS } else { reduced }
}

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn fornberg_finite_difference_weights(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let order_value = values[1];
    if !(1..=MAX_NODES as i64).contains(&n_value) || !(0..=3).contains(&order_value)
        || order_value >= n_value || length != n_value as usize + 3 { return -1; }
    let n = n_value as usize;
    let target = values[2];
    if !(0..MODULUS).contains(&target) { return -1; }
    for index in 0..n {
        let node = values[3 + index];
        if !(0..MODULUS).contains(&node) { return -1; }
        if (0..index).any(|previous| values[3 + previous] == node) { return -1; }
    }

    let mut table = [[0i64; 4]; MAX_NODES];
    table[0][0] = 1;
    let mut previous_product = 1i64;
    for new_index in 1..n {
        let old_last = table[new_index - 1];
        let mut product = 1i64;
        let node = values[3 + new_index];
        let factor = mod_norm(node - target);
        let max_d = std::cmp::min(new_index, order_value as usize);
        for old_index in 0..new_index {
            let difference = mod_norm(node - values[3 + old_index]);
            product = product * difference % MODULUS;
            let inverse_difference = mod_pow(difference, MODULUS - 2);
            for derivative in (0..=max_d).rev() {
                let lower = if derivative == 0 { 0 } else { table[old_index][derivative - 1] };
                let numerator = mod_norm(factor * table[old_index][derivative]
                    - derivative as i64 * lower);
                table[old_index][derivative] = numerator * inverse_difference % MODULUS;
            }
        }
        let product_inverse = mod_pow(product, MODULUS - 2);
        let last_factor = mod_norm(values[2 + new_index] - target);
        for derivative in 0..=max_d {
            let lower = if derivative == 0 { 0 } else { old_last[derivative - 1] };
            let numerator = mod_norm(derivative as i64 * lower - last_factor * old_last[derivative]);
            table[new_index][derivative] = previous_product * product_inverse % MODULUS * numerator % MODULUS;
        }
        previous_product = product;
    }

    let required = 8 * (n + 1);
    if output.is_null() || capacity < required { return -2; }
    unsafe {
        store_i64_le(output, 0, n_value);
        for index in 0..n {
            store_i64_le(output, 8 * (index + 1), table[index][order_value as usize]);
        }
    }
    required as i64
}
