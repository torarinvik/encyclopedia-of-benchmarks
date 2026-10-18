const INVALID_RESULT: i64 = -1;
const DIMENSION: usize = 32;
const MODULUS: i64 = 3329;
const SAMPLES: usize = 128;
const MAX_MESSAGE_BYTES: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 8358;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_byte(mut hash: u64, byte: u8) -> u64 {
    hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    hash
}

fn hash_word(hash_input: u64, value: i64) -> u64 {
    let mut hash = hash_byte(hash_input, (value & 255) as u8);
    hash = hash_byte(hash, ((value >> 8) & 255) as u8);
    hash
}

#[no_mangle]
pub unsafe extern "C" fn lwe_encryption(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let message_length_value = values[0];
    if message_length_value < 1 || message_length_value > MAX_MESSAGE_BYTES as i64 { return INVALID_RESULT; }
    let message_length = message_length_value as usize;
    let message_start = 1;
    let message_end = message_start + message_length;
    let secret_start = message_end;
    let matrix_start = secret_start + DIMENSION;
    let error_start = matrix_start + SAMPLES * DIMENSION;
    let subset_start = error_start + SAMPLES;
    let subset_count = message_length * 8 * SAMPLES;
    if length != subset_start + subset_count { return INVALID_RESULT; }

    if values[message_start..message_end].iter().any(|&value| !(0..=255).contains(&value)) { return INVALID_RESULT; }
    if values[secret_start..matrix_start].iter().any(|&value| !(0..MODULUS).contains(&value)) { return INVALID_RESULT; }
    if values[matrix_start..error_start].iter().any(|&value| !(0..MODULUS).contains(&value)) { return INVALID_RESULT; }
    if values[error_start..subset_start].iter().any(|&value| !(0..=6).contains(&value)) { return INVALID_RESULT; }
    if values[subset_start..].iter().any(|&value| value != 0 && value != 1) { return INVALID_RESULT; }

    let mut public_b = [0_i64; SAMPLES];
    for row in 0..SAMPLES {
        let mut sum = 0_i64;
        for column in 0..DIMENSION {
            sum += values[matrix_start + row * DIMENSION + column] * values[secret_start + column];
        }
        let error = values[error_start + row] - 3;
        public_b[row] = (sum + error).rem_euclid(MODULUS);
    }

    let mut hash = FNV_OFFSET_BASIS;
    let mut decoded_message = [0_u8; MAX_MESSAGE_BYTES];
    let mut subset_cursor = 0;
    for byte_index in 0..message_length {
        let message_byte = values[message_start + byte_index] as u8;
        let mut decoded_byte = 0_u8;
        for bit_index in 0..8 {
            let message_bit = (message_byte >> (7 - bit_index)) & 1;
            let mut u_accumulator = [0_i64; DIMENSION];
            let mut v_accumulator = i64::from(message_bit) * (MODULUS / 2);
            for row in 0..SAMPLES {
                let selected = values[subset_start + subset_cursor];
                subset_cursor += 1;
                if selected != 0 {
                    for column in 0..DIMENSION {
                        u_accumulator[column] += values[matrix_start + row * DIMENSION + column];
                    }
                    v_accumulator += public_b[row];
                }
            }
            let mut u = [0_i64; DIMENSION];
            for column in 0..DIMENSION {
                u[column] = u_accumulator[column] % MODULUS;
                hash = hash_word(hash, u[column]);
            }
            let v = v_accumulator % MODULUS;
            hash = hash_word(hash, v);

            let mut dot = 0_i64;
            for column in 0..DIMENSION { dot += u[column] * values[secret_start + column]; }
            let difference = (v - dot).rem_euclid(MODULUS);
            let decrypted_bit = if difference >= 832 && difference < 2496 { 1 } else { 0 };
            decoded_byte = (decoded_byte << 1) | decrypted_bit;
        }
        decoded_message[byte_index] = decoded_byte;
    }
    for &byte in &decoded_message[..message_length] { hash = hash_byte(hash, byte); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
