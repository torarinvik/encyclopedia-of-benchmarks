const MAX_STATES: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_STATES + 2;

#[no_mangle]
pub unsafe extern "C" fn sum_over_subsets_zeta_transform(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let bit_count = input[0];
    if !(0..=6).contains(&bit_count) {
        return -1;
    }
    let state_count = 1usize << bit_count as usize;
    if length != state_count + 1 {
        return -1;
    }

    let mut transformed = [0_i64; MAX_STATES];
    for mask in 0..state_count {
        let value = input[mask + 1];
        if !(0..=1_000_000).contains(&value) {
            return -1;
        }
        transformed[mask] = value;
    }
    for bit_index in 0..bit_count as usize {
        let bit = 1usize << bit_index;
        for mask in 0..state_count {
            if mask & bit != 0 {
                transformed[mask] += transformed[mask ^ bit];
            }
        }
    }

    let mut checksum = 0_i64;
    for mask in 0..state_count {
        checksum += (mask as i64 + 1) * transformed[mask];
    }
    checksum
}
