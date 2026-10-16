/// Count bounded ASCII tokens in insertion order, matching the pinned Java routine.
const MAX_INPUT: usize = 256;
const MAX_WORDS: usize = 128;
const TABLE_SIZE: usize = 512;

#[inline]
fn is_space_byte(value: i64) -> bool {
    matches!(value, 9 | 10 | 11 | 12 | 13 | 32)
}

unsafe fn token_hash(input: *const i64, start: usize, length: usize) -> usize {
    let mut hash = 0usize;
    for offset in 0..length {
        hash = (hash * 31 + *input.add(start + offset) as usize) % 1_000_003;
    }
    hash
}

unsafe fn token_equal(input: *const i64, start: usize, length: usize,
                      other_start: usize, other_length: usize) -> bool {
    if length != other_length { return false; }
    for offset in 0..length {
        if *input.add(start + offset) != *input.add(other_start + offset) { return false; }
    }
    true
}

unsafe fn write_count(output: *mut u8, mut position: usize, mut count: usize) -> usize {
    let mut digits = [0u8; 3];
    let mut digit_count = 0usize;
    loop {
        digits[digit_count] = b'0' + (count % 10) as u8;
        digit_count += 1;
        count /= 10;
        if count == 0 { break; }
    }
    while digit_count != 0 {
        digit_count -= 1;
        *output.add(position) = digits[digit_count];
        position += 1;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn map_reduce(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_INPUT || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !is_space_byte(value) && !(32..=126).contains(&value) { return -1; }
    }

    let mut starts = [0usize; MAX_WORDS];
    let mut lengths = [0usize; MAX_WORDS];
    let mut counts = [0usize; MAX_WORDS];
    let mut table = [0usize; TABLE_SIZE];
    let mut unique_count = 0usize;
    let mut begin = 0usize;
    let mut end = length;
    while begin < end && *input.add(begin) <= 32 { begin += 1; }
    while end > begin && *input.add(end - 1) <= 32 { end -= 1; }

    if begin == end {
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1;
        table[0] = 1;
    } else {
        let mut cursor = begin;
        while cursor < end {
            while cursor < end && is_space_byte(*input.add(cursor)) { cursor += 1; }
            if cursor == end { break; }
            let start = cursor;
            while cursor < end && !is_space_byte(*input.add(cursor)) { cursor += 1; }
            let token_length = cursor - start;
            let mut slot = token_hash(input, start, token_length) % TABLE_SIZE;
            while table[slot] != 0 {
                let item = table[slot] - 1;
                if token_equal(input, start, token_length, starts[item], lengths[item]) {
                    counts[item] += 1;
                    break;
                }
                slot = (slot + 1) % TABLE_SIZE;
            }
            if table[slot] == 0 {
                starts[unique_count] = start;
                lengths[unique_count] = token_length;
                counts[unique_count] = 1;
                table[slot] = unique_count + 1;
                unique_count += 1;
            }
        }
    }

    let mut required = 0usize;
    for item in 0..unique_count {
        let mut digits = 1usize;
        let mut value = counts[item];
        while value >= 10 { value /= 10; digits += 1; }
        required += lengths[item] + 2 + digits + usize::from(item != 0);
    }
    if output.is_null() || output_capacity < required { return -2; }

    let mut written = 0usize;
    for item in 0..unique_count {
        if item != 0 { *output.add(written) = b','; written += 1; }
        for offset in 0..lengths[item] {
            *output.add(written) = *input.add(starts[item] + offset) as u8;
            written += 1;
        }
        *output.add(written) = b':'; written += 1;
        *output.add(written) = b' '; written += 1;
        written = write_count(output, written, counts[item]);
    }
    written as i64
}
