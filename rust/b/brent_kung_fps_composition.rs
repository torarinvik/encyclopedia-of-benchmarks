const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_BLOCKS: usize = 6;
const MAX_POWERS: usize = 7;

type Polynomial = [i64; MAX_N];

fn multiply_truncated(left: &Polynomial, right: &Polynomial, n: usize) -> Polynomial {
    let mut product = [0i64; MAX_N];
    for i in 0..n {
        for j in 0..(n - i) {
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    product
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn brent_kung_fps_composition(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != 1 + 2 * n { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) || input[1 + n] != 0 {
        return -1;
    }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut block_size = 1usize;
    while block_size * block_size < n { block_size += 1; }
    let block_count = (n + block_size - 1) / block_size;
    let mut powers = [[0i64; MAX_N]; MAX_POWERS];
    let mut blocks = [[0i64; MAX_N]; MAX_BLOCKS];
    let mut inner = [0i64; MAX_N];
    for degree in 0..n { inner[degree] = input[1 + n + degree]; }
    powers[0][0] = 1;
    for exponent in 1..=block_size {
        powers[exponent] = multiply_truncated(&powers[exponent - 1], &inner, n);
    }
    for block in 0..block_count {
        for offset in 0..block_size {
            let coefficient_index = block * block_size + offset;
            if coefficient_index >= n { break; }
            let coefficient = input[1 + coefficient_index];
            for degree in 0..n {
                blocks[block][degree] =
                    (blocks[block][degree] + coefficient * powers[offset][degree]) % MODULUS;
            }
        }
    }
    let mut composed = blocks[block_count - 1];
    for block in (1..block_count).rev() {
        composed = multiply_truncated(&composed, &powers[block_size], n);
        for degree in 0..n {
            composed[degree] = (composed[degree] + blocks[block - 1][degree]) % MODULUS;
        }
    }
    for degree in 0..n { unsafe { store_le(output, 8 * degree, composed[degree]); } }
    bytes as i64
}
