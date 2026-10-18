const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 69;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn bounded_power(base: i64, exponent: i64) -> i64 {
    let mut result = 1_i64;
    for _ in 0..exponent { result *= base; }
    result
}

fn hash_byte(hash: u64, value: u8) -> u64 {
    (hash ^ u64::from(value)).wrapping_mul(FNV_PRIME)
}

#[no_mangle]
pub unsafe extern "C" fn rsa_ruby_byte_chunk(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(packed, length);
    let modulus = values[0];
    let public_exponent = values[1];
    let private_exponent = values[2];
    let message_length = values[3];
    if modulus != 33 || !(1..=7).contains(&public_exponent) || !(1..=7).contains(&private_exponent) ||
        !(1..=64).contains(&message_length) || length != (4 + message_length) as usize {
        return INVALID_RESULT;
    }
    let message = &values[4..];
    if message.iter().any(|&value| !(0..33).contains(&value)) { return INVALID_RESULT; }
    let ciphertexts: Vec<i64> = message.iter()
        .map(|&value| bounded_power(value, public_exponent) % modulus)
        .collect();
    let mut hash = FNV_OFFSET_BASIS;
    for &value in &ciphertexts {
        hash = hash_byte(hash, b'0' + (value / 10) as u8);
        hash = hash_byte(hash, b'0' + (value % 10) as u8);
    }
    for &ciphertext in &ciphertexts {
        let recovered = bounded_power(ciphertext, private_exponent) % modulus;
        hash = hash_byte(hash, recovered as u8);
    }
    (hash & LOW_63_MASK) as i64
}
