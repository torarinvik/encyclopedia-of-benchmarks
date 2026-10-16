const MAX_BYTES: usize = 64;
const MAX_PARSED_BYTES: usize = 65;
const UINT32_MODULUS: u64 = 1_u64 << 32;

#[no_mangle]
pub unsafe extern "C" fn djb2(input: *const i64, length: usize) -> i64 {
    if length > MAX_PARSED_BYTES || (length > 0 && input.is_null()) { return -1; }
    if length > MAX_BYTES { return -1; }
    let mut hash = 5381_u64;
    for index in 0..length {
        let code_point = *input.add(index);
        if !(0..=255).contains(&code_point) { return -1; }
        hash = (hash * 33 + code_point as u64) % UINT32_MODULUS;
    }
    hash as i64
}
