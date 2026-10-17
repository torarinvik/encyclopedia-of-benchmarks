/// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
#[no_mangle]
pub unsafe extern "C" fn modulo(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let a = values[0];
    let b = values[1];
    if !(0..=4_294_967_295).contains(&a) || !(1..=4_294_967_295).contains(&b) {
        return -1;
    }
    a % b
}
