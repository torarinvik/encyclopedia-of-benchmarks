const DELTA: u32 = 0x9e37_79b9;
const DECRYPT_SUM: u32 = 0xc6ef_3720;

fn combine_words(low: u32, high: u32) -> u64 {
    ((high as u64) << 32) | low as u64
}

fn tea_encrypt(block: u64, key0: u64, key1: u64) -> u64 {
    let mut b0 = block as u32;
    let mut b1 = (block >> 32) as u32;
    let k0 = key0 as u32;
    let k1 = (key0 >> 32) as u32;
    let k2 = key1 as u32;
    let k3 = (key1 >> 32) as u32;
    let mut sum = 0u32;
    for _ in 0..32 {
        sum = sum.wrapping_add(DELTA);
        b0 = b0.wrapping_add(((b1 << 4).wrapping_add(k0)) ^ b1.wrapping_add(sum) ^ ((b1 >> 5).wrapping_add(k1)));
        b1 = b1.wrapping_add(((b0 << 4).wrapping_add(k2)) ^ b0.wrapping_add(sum) ^ ((b0 >> 5).wrapping_add(k3)));
    }
    ((b1 as u64) << 32) | b0 as u64
}

fn tea_decrypt(block: u64, key0: u64, key1: u64) -> u64 {
    let mut b0 = block as u32;
    let mut b1 = (block >> 32) as u32;
    let k0 = key0 as u32;
    let k1 = (key0 >> 32) as u32;
    let k2 = key1 as u32;
    let k3 = (key1 >> 32) as u32;
    let mut sum = DECRYPT_SUM;
    for _ in 0..32 {
        b1 = b1.wrapping_sub(((b0 << 4).wrapping_add(k2)) ^ b0.wrapping_add(sum) ^ ((b0 >> 5).wrapping_add(k3)));
        b0 = b0.wrapping_sub(((b1 << 4).wrapping_add(k0)) ^ b1.wrapping_add(sum) ^ ((b1 >> 5).wrapping_add(k1)));
        sum = sum.wrapping_sub(DELTA);
    }
    ((b1 as u64) << 32) | b0 as u64
}

fn store_u64_le(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (value >> (byte * 8)) as u8; }
    }
}

/// Return ciphertext and the decrypted round-trip block as little-endian u64s.
#[no_mangle]
pub unsafe extern "C" fn tea(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 6 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    if output.is_null() || output_capacity < 16 {
        return -2;
    }
    let word = |index: usize| values[index] as i32 as u32;
    let block = combine_words(word(0), word(1));
    let key0 = combine_words(word(2), word(3));
    let key1 = combine_words(word(4), word(5));
    let ciphertext = tea_encrypt(block, key0, key1);
    let recovered = tea_decrypt(ciphertext, key0, key1);
    store_u64_le(output, 0, ciphertext);
    store_u64_le(output, 8, recovered);
    16
}
