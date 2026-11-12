const MAX_N: usize = 8;
const MAX_SIZE: usize = 1 << MAX_N;
const MAX_INPUT: usize = 1 + 2 * MAX_SIZE;
const MODULUS: i64 = 998_244_353;

fn xor_walsh_transform(values: &mut [i64; MAX_SIZE], size: usize) {
    let mut half = 1;
    while half < size {
        let mut block = 0;
        while block < size {
            for offset in 0..half {
                let left = values[block + offset];
                let right = values[block + half + offset];
                values[block + offset] = (left + right) % MODULUS;
                values[block + half + offset] = (left - right + MODULUS) % MODULUS;
            }
            block += 2 * half;
        }
        half *= 2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bitwise_xor_convolution(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(0..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let size = 1usize << n;
    if length != 1 + 2 * size { return -1; }
    if values[1..].iter().any(|&value| !(0..MODULUS).contains(&value)) { return -1; }

    let output_bytes = 8 * size;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut first = [0i64; MAX_SIZE];
    let mut second = [0i64; MAX_SIZE];
    first[..size].copy_from_slice(&values[1..1 + size]);
    second[..size].copy_from_slice(&values[1 + size..]);
    xor_walsh_transform(&mut first, size);
    xor_walsh_transform(&mut second, size);
    for index in 0..size { first[index] = (first[index] * second[index]) % MODULUS; }
    xor_walsh_transform(&mut first, size);

    let mut inverse_size = 1i64;
    for _ in 0..n { inverse_size = (inverse_size * ((MODULUS + 1) / 2)) % MODULUS; }
    for index in 0..size {
        let bytes = ((first[index] * inverse_size) % MODULUS).to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(8 * index), 8);
    }
    output_bytes as i64
}
