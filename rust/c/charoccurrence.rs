const MAX_INPUT: usize = 128;
const MAX_OUTPUT: usize = 1024;

fn append_decimal(buffer: &mut [u8; MAX_OUTPUT], mut offset: usize, value: usize) -> usize {
    let mut digits = [0u8; 3];
    let mut count = 0;
    let mut remaining = value;
    loop {
        digits[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[offset] = digits[count];
        offset += 1;
    }
    offset
}

/// Count ASCII codepoints and emit a sorted `codepoint=count` map.
#[no_mangle]
pub unsafe extern "C" fn charoccurrence(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if length > MAX_INPUT || (length > 0 && values.is_null()) { return -1; }
    let mut counts = [0usize; 128];
    for index in 0..length {
        let value = *values.add(index);
        if !(0..=127).contains(&value) { return -1; }
        counts[value as usize] += 1;
    }

    let mut encoded = [0u8; MAX_OUTPUT];
    let mut used = 0;
    for (codepoint, &count) in counts.iter().enumerate() {
        if count == 0 { continue; }
        if used > 0 {
            encoded[used] = b',';
            used += 1;
        }
        used = append_decimal(&mut encoded, used, codepoint);
        encoded[used] = b'=';
        used += 1;
        used = append_decimal(&mut encoded, used, count);
    }
    if used > capacity { return -2; }
    if used > 0 && output.is_null() { return -2; }
    if used > 0 {
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, used);
    }
    used as i64
}
