const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 69;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn power_mod(base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1_i64;
    let mut power = base % modulus;
    while exponent > 0 {
        if exponent & 1 != 0 { result = (result * power) % modulus; }
        power = (power * power) % modulus;
        exponent /= 2;
    }
    result
}

fn hash_u32(mut hash: u64, value: i64) -> u64 {
    let bits = value as u32;
    for byte in 0..4 {
        hash = (hash ^ u64::from((bits >> (byte * 8)) & 255)).wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn rsa_explicit_key_transform(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(packed, length);
    let modulus = values[0];
    let public_exponent = values[1];
    let private_exponent = values[2];
    let message_length = values[3];
    if !(128..=55295).contains(&modulus) || !(1..=1_000_000).contains(&public_exponent) ||
        !(1..=1_000_000).contains(&private_exponent) || !(1..=64).contains(&message_length) ||
        length != (4 + message_length) as usize { return INVALID_RESULT; }
    let message = &values[4..];
    if message.iter().any(|&value| !(0..=127).contains(&value) || value >= modulus) {
        return INVALID_RESULT;
    }
    let mut hash = FNV_OFFSET_BASIS;
    for &value in message { hash = hash_u32(hash, power_mod(value, public_exponent, modulus)); }
    for &value in message {
        let ciphertext = power_mod(value, public_exponent, modulus);
        hash = hash_u32(hash, power_mod(ciphertext, private_exponent, modulus));
    }
    (hash & LOW_63_MASK) as i64
}
