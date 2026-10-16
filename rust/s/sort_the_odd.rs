const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

#[no_mangle]
pub unsafe extern "C" fn sort_the_odd_benchmark(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) {
        return -1;
    }
    let values: &[i64] = if length == 0 {
        &[]
    } else {
        std::slice::from_raw_parts(input, length)
    };

    let mut odds = Vec::new();
    for &value in values {
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) {
            return -1;
        }
        if value % 2 != 0 {
            odds.push(value);
        }
    }
    odds.sort_unstable();

    let mut odd_index = 0;
    let mut checksum = 0_i64;
    for (index, &original) in values.iter().enumerate() {
        let value = if original % 2 != 0 {
            let sorted = odds[odd_index];
            odd_index += 1;
            sorted
        } else {
            original
        };
        checksum += (index as i64 + 1) * (value + CHECKSUM_OFFSET);
    }
    checksum
}
