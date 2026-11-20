const MAX_VALUES: usize = 32;
const MAX_HIGH_BITS: usize = 96;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 35;

#[no_mangle]
pub unsafe extern "C" fn elias_fano_monotone_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let count_value = *input;
    let upper_bound = *input.add(1);
    if !(1..=MAX_VALUES as i64).contains(&count_value)
        || !(0..=1_000_000).contains(&upper_bound)
        || count_value > upper_bound + 1
    {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 2 {
        return -1;
    }

    let mut values = [0i64; MAX_VALUES];
    let mut previous = -1i64;
    for i in 0..count {
        let value = *input.add(i + 2);
        if value < 0 || value > upper_bound || value < previous {
            return -1;
        }
        values[i] = value;
        previous = value;
    }

    let mut low_width = 0u32;
    while (count as i64) * (1i64 << (low_width + 1)) <= upper_bound + 1 {
        low_width += 1;
    }
    let width = 1i64 << low_width;
    let low_mask = width - 1;
    let high_length = (upper_bound / width) as usize + count;
    if high_length < count || high_length > MAX_HIGH_BITS {
        return -1;
    }

    let mut low_parts = [0i64; MAX_VALUES];
    let mut high_bits = [false; MAX_HIGH_BITS];
    for i in 0..count {
        low_parts[i] = values[i] & low_mask;
        let position = (values[i] / width) as usize + i;
        if position >= high_length {
            return -1;
        }
        high_bits[position] = true;
    }

    let mut checksum = 0i64;
    let mut item_index = 0usize;
    for position in 0..high_length {
        if high_bits[position] {
            if item_index >= count || position < item_index {
                return -1;
            }
            let high_part = (position - item_index) as i64;
            let decoded = high_part * width + low_parts[item_index];
            checksum += (item_index as i64 + 1) * decoded;
            item_index += 1;
        }
    }
    if item_index != count {
        return -1;
    }
    checksum
}
