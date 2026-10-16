#[derive(Clone, Copy)]
struct Matrix2([i64; 4]);
fn mul(a: Matrix2, b: Matrix2) -> Matrix2 {
    let mut c = Matrix2([0; 4]);
    for r in 0..2 { for col in 0..2 { for k in 0..2 { c.0[r*2+col] += a.0[r*2+k] * b.0[k*2+col]; } } }
    c
}
fn power(a: Matrix2, e: i64) -> Matrix2 {
    if e == 0 { return Matrix2([1, 0, 0, 1]); }
    if e & 1 == 1 { return mul(power(a, e - 1), a); }
    let half = power(a, e / 2); mul(half, half)
}
#[no_mangle]
pub unsafe extern "C" fn matrix_exponentiation_recursive(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 5 { return -2; }
    let v = std::slice::from_raw_parts(input, length);
    if !(0..=30).contains(&v[0]) || v[1..].iter().any(|x| !(-1..=1).contains(x)) { return -2; }
    if output.is_null() || capacity < 32 { return -3; }
    let result = power(Matrix2([v[1], v[2], v[3], v[4]]), v[0]);
    let out = std::slice::from_raw_parts_mut(output, 32);
    for (i, value) in result.0.iter().enumerate() { out[i*8..i*8+8].copy_from_slice(&value.to_le_bytes()); }
    4
}
