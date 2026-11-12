const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_M: usize = 8;
const LEAF_BASE: usize = 8;
const NODE_CAPACITY: usize = 16;
const COEFFICIENT_CAPACITY: usize = 9;
const MAX_INPUT: usize = 18;
type Polynomial = [i64; COEFFICIENT_CAPACITY];

fn store_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = ((bits >> (8 * byte)) & 255) as u8; }
}

fn trim(polynomial: &Polynomial, mut length: usize) -> usize {
    while length > 1 && polynomial[length - 1] == 0 { length -= 1; }
    length
}

fn multiply(left: &Polynomial, left_length: usize, right: &Polynomial,
            right_length: usize, product: &mut Polynomial) -> usize {
    let length = left_length + right_length - 1;
    product.fill(0);
    for i in 0..left_length {
        for j in 0..right_length {
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    length
}

fn remainder(dividend: &Polynomial, dividend_length: usize, divisor: &Polynomial,
             divisor_length: usize, result: &mut Polynomial) -> usize {
    result.fill(0);
    if divisor_length == 1 && divisor[0] == 1 { return 1; }
    result[..dividend_length].copy_from_slice(&dividend[..dividend_length]);
    let mut length = trim(result, dividend_length);
    while length >= divisor_length {
        let shift = length - divisor_length;
        let factor = result[length - 1];
        for degree in 0..divisor_length {
            let slot = shift + degree;
            result[slot] = (result[slot] - factor * divisor[degree]) % MODULUS;
            if result[slot] < 0 { result[slot] += MODULUS; }
        }
        length = trim(result, length);
    }
    length
}

#[no_mangle]
pub unsafe extern "C" fn multipoint_evaluation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 1 || input[1] > MAX_M as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + n + m { return -1; }
    for &value in &input[2..] {
        if value < 0 || value >= MODULUS { return -1; }
    }
    if input[1 + n] == 0 { return -1; }
    let bytes = 8 * m;
    if output.is_null() || capacity < bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, bytes) };

    let mut products = [[0_i64; COEFFICIENT_CAPACITY]; NODE_CAPACITY];
    let mut remainders = [[0_i64; COEFFICIENT_CAPACITY]; NODE_CAPACITY];
    let mut product_lengths = [0_usize; NODE_CAPACITY];
    let mut remainder_lengths = [0_usize; NODE_CAPACITY];
    let mut starts = [0_usize; NODE_CAPACITY];
    let mut spans = [0_usize; NODE_CAPACITY];
    for node in 1..NODE_CAPACITY { products[node][0] = 1; product_lengths[node] = 1; }
    for i in 0..m {
        let leaf = LEAF_BASE + i;
        products[leaf][0] = if input[2 + n + i] == 0 { 0 } else { MODULUS - input[2 + n + i] };
        products[leaf][1] = 1;
        product_lengths[leaf] = 2;
    }
    for node in (1..LEAF_BASE).rev() {
        let left = products[2 * node];
        let right = products[2 * node + 1];
        product_lengths[node] = multiply(&left, product_lengths[2 * node], &right,
            product_lengths[2 * node + 1], &mut products[node]);
    }
    starts[1] = 0;
    spans[1] = LEAF_BASE;
    for node in 1..LEAF_BASE {
        spans[2 * node] = spans[node] / 2;
        spans[2 * node + 1] = spans[node] / 2;
        starts[2 * node] = starts[node];
        starts[2 * node + 1] = starts[node] + spans[node] / 2;
    }
    let mut input_poly = [0_i64; COEFFICIENT_CAPACITY];
    input_poly[..n].copy_from_slice(&input[2..2 + n]);
    remainder_lengths[1] = remainder(&input_poly, n, &products[1], product_lengths[1], &mut remainders[1]);
    for node in 1..LEAF_BASE {
        for side in 0..2 {
            let child = 2 * node + side;
            if starts[child] < m {
                let parent_remainder = remainders[node];
                remainder_lengths[child] = remainder(&parent_remainder, remainder_lengths[node],
                    &products[child], product_lengths[child], &mut remainders[child]);
            }
        }
    }
    for i in 0..m { store_le(output, 8 * i, remainders[LEAF_BASE + i][0]); }
    bytes as i64
}
