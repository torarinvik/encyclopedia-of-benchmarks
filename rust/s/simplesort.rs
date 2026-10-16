const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub unsafe extern "C" fn simplesort(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) {
        return INVALID_RESULT;
    }
    let input: &[i64] = if length == 0 { &[] } else { std::slice::from_raw_parts(values, length) };
    let mut working = [0_i64; MAX_LENGTH];
    for (index, &value) in input.iter().enumerate() {
        if value < MIN_VALUE || value > MAX_VALUE { return INVALID_RESULT; }
        working[index] = value;
    }

    for i in 0..length {
        for j in 0..length {
            if working[i] < working[j] {
                working.swap(i, j);
            }
        }
    }
    let mut checksum = 0_i64;
    for index in 0..length {
        checksum += (index as i64 + 1) * (working[index] + CHECKSUM_OFFSET);
    }
    checksum
}
