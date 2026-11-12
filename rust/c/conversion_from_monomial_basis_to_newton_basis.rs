const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 12;
const MAX_INPUT: usize = 25;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn conversion_from_monomial_basis_to_newton_basis(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != 1 + 2 * n { return -1; }
    for &value in &input[1..] { if value < 0 || value >= MODULUS { return -1; } }

    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut residual = [0_i64; MAX_N];
    let mut answer = [0_i64; MAX_N];
    residual[..n].copy_from_slice(&input[1..n + 1]);
    let mut active = n;
    for i in 0..n {
        let node = input[n + 1 + i];
        let mut value = 0_i64;
        for degree in (0..active).rev() { value = (value * node + residual[degree]) % MODULUS; }
        answer[i] = value;
        if active == 1 { continue; }
        let mut quotient = [0_i64; MAX_N];
        quotient[active - 2] = residual[active - 1];
        let mut degree = active - 2;
        while degree > 0 {
            quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % MODULUS;
            degree -= 1;
        }
        residual[..active - 1].copy_from_slice(&quotient[..active - 1]);
        active -= 1;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, answer[i]); } }
    bytes as i64
}
