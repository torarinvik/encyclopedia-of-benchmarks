const MAX_TABLE_SIZE: usize = 256;
const DIGEST_MASK: u64 = 0x7fff_ffff_ffff_ffff;

#[no_mangle]
pub unsafe extern "C" fn hpcc_random_access(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let size_value = *input;
    if !(2..=MAX_TABLE_SIZE as i64).contains(&size_value)
        || (size_value & (size_value - 1)) != 0
    {
        return -1;
    }

    let size = size_value as usize;
    let mut table = [0u64; MAX_TABLE_SIZE];
    for (index, entry) in table[..size].iter_mut().enumerate() {
        *entry = index as u64;
    }

    let mut ran = 1u64;
    for _ in 0..4 * size {
        let feedback = if ran >> 63 != 0 { 7 } else { 0 };
        ran = ran.wrapping_shl(1) ^ feedback;
        table[(ran as usize) & (size - 1)] ^= ran;
    }

    let mut digest = 0u64;
    for (index, &value) in table[..size].iter().enumerate() {
        digest = digest.wrapping_add((index as u64 + 1).wrapping_mul(value));
    }
    (digest & DIGEST_MASK) as i64
}
