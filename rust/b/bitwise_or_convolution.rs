const MAX_N: usize = 8;
const MAX_SIZE: usize = 1 << MAX_N;
const MAX_INPUT: usize = 1 + 2 * MAX_SIZE;
const MODULUS: i64 = 998_244_353;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn bitwise_or_convolution(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let nv = values[0];
    if !(0..=MAX_N as i64).contains(&nv) { return -1; }
    let n = nv as usize;
    let size = 1usize << n;
    if length != 1 + 2 * size { return -1; }
    if values[1..].iter().any(|&x| !(0..MODULUS).contains(&x)) { return -1; }
    let bytes = 8 * size;
    if output.is_null() || capacity < bytes { return -2; }
    let mut a = [0i64; MAX_SIZE];
    let mut b = [0i64; MAX_SIZE];
    a[..size].copy_from_slice(&values[1..1 + size]);
    b[..size].copy_from_slice(&values[1 + size..]);
    for bit in 0..n {
        let bit_mask = 1usize << bit;
        for mask in 0..size {
            if mask & bit_mask != 0 {
                a[mask] = (a[mask] + a[mask ^ bit_mask]) % MODULUS;
                b[mask] = (b[mask] + b[mask ^ bit_mask]) % MODULUS;
            }
        }
    }
    for i in 0..size { a[i] = (a[i] * b[i]) % MODULUS; }
    for bit in 0..n {
        let bit_mask = 1usize << bit;
        for mask in 0..size {
            if mask & bit_mask != 0 {
                a[mask] -= a[mask ^ bit_mask];
                if a[mask] < 0 { a[mask] += MODULUS; }
            }
        }
    }
    for i in 0..size { store_i64_le(output, 8 * i, a[i]); }
    bytes as i64
}
