const MAX_INPUT_VALUES: usize = 66;
const MAX_DECODED_LENGTH: usize = 52;

fn decode_group(values: &[i64], start: usize, count: usize) -> Option<u32> {
    let mut value = 0u64;
    for index in 0..5 {
        let digit = if index < count {
            let byte = values[start + index];
            if !(33..=117).contains(&byte) { return None; }
            (byte - 33) as u64
        } else {
            84
        };
        value = value * 85 + digit;
    }
    if value > u32::MAX as u64 { return None; }
    Some(value as u32)
}

#[no_mangle]
pub unsafe extern "C" fn base85(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let mode = values[0];
    let payload = &values[1..];
    let mut output_length = 0usize;

    if mode == 0 {
        if payload.iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }
        let remainder = payload.len() % 4;
        output_length = (payload.len() / 4) * 5 + (if remainder == 0 { 0 } else { remainder + 1 });
    } else if mode == 1 {
        if payload.len() % 5 == 1 { return -1; }
        let mut offset = 0usize;
        while offset < payload.len() {
            let count = (payload.len() - offset).min(5);
            if decode_group(payload, offset, count).is_none() { return -1; }
            output_length += if count == 5 { 4 } else { count - 1 };
            offset += count;
        }
        if output_length > MAX_DECODED_LENGTH { return -1; }
    } else {
        return -1;
    }

    if output_capacity < output_length || (output_length != 0 && output.is_null()) { return -2; }
    let mut written = 0usize;
    if mode == 0 {
        const POWERS: [u64; 5] = [52_200_625, 614_125, 7_225, 85, 1];
        let mut offset = 0usize;
        while offset < payload.len() {
            let count = (payload.len() - offset).min(4);
            let mut value = 0u64;
            for byte in 0..4 {
                value <<= 8;
                if byte < count { value |= payload[offset + byte] as u64; }
            }
            for digit in 0..5 {
                let encoded = (value / POWERS[digit] + 33) as u8;
                value %= POWERS[digit];
                if count == 4 || digit < count + 1 {
                    *output.add(written) = encoded;
                    written += 1;
                }
            }
            offset += 4;
        }
    } else {
        let mut offset = 0usize;
        while offset < payload.len() {
            let count = (payload.len() - offset).min(5);
            let value = decode_group(payload, offset, count).unwrap() as u64;
            let byte_count = if count == 5 { 4 } else { count - 1 };
            for byte in 0..byte_count {
                *output.add(written) = (value >> (24 - 8 * byte)) as u8;
                written += 1;
            }
            offset += count;
        }
    }
    written as i64
}
