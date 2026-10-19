const MAX_INPUT_BYTES: usize = 4096;
const MAX_OUTPUT_BYTES: usize = 2949;
const HEADER: &[u8] = b"begin 755 uustart.file \n";

fn scan(input: &[i64]) -> Option<usize> {
    if input.len() > MAX_INPUT_BYTES || input.iter().any(|value| !(0..=255).contains(value)) {
        return None;
    }
    if input.len() < HEADER.len() + 5
        || !input.iter().take(HEADER.len()).zip(HEADER).all(|(value, byte)| *value == i64::from(*byte)) {
        return None;
    }

    let mut cursor = HEADER.len();
    let mut total = 0usize;
    while cursor < input.len() {
        let marker = input[cursor] as usize;
        cursor += 1;
        if marker == 32 {
            if cursor + 4 != input.len()
                || input[cursor] != 10 || input[cursor + 1] != i64::from(b'e')
                || input[cursor + 2] != i64::from(b'n') || input[cursor + 3] != i64::from(b'd') {
                return None;
            }
            return (total <= MAX_OUTPUT_BYTES).then_some(total);
        }
        let count = marker.checked_sub(32)?;
        if !(1..=45).contains(&count) {
            return None;
        }
        let encoded = 4 * ((count + 2) / 3);
        if cursor + encoded >= input.len() || input[cursor + encoded] != 10 {
            return None;
        }
        if input[cursor..cursor + encoded].iter().any(|symbol| !(32..=95).contains(symbol)) {
            return None;
        }
        total += count;
        if total > MAX_OUTPUT_BYTES {
            return None;
        }
        cursor += encoded + 1;
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn uudecode(input: *const i64, length: usize,
                                   output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length > MAX_INPUT_BYTES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let decoded_length = match scan(values) {
        Some(size) => size,
        None => return -1,
    };
    if output.is_null() || capacity < decoded_length {
        return -2;
    }

    let result = std::slice::from_raw_parts_mut(output, capacity);
    let mut cursor = HEADER.len();
    let mut written = 0usize;
    loop {
        let count = (values[cursor] - 32) as usize;
        cursor += 1;
        if count == 0 {
            break;
        }
        let encoded = 4 * ((count + 2) / 3);
        let mut emitted = 0usize;
        for _ in (0..encoded).step_by(4) {
            let a = (values[cursor] - 32) as u32;
            let b = (values[cursor + 1] - 32) as u32;
            let c = (values[cursor + 2] - 32) as u32;
            let d = (values[cursor + 3] - 32) as u32;
            cursor += 4;
            result[written] = ((a << 2) | (b >> 4)) as u8;
            written += 1;
            emitted += 1;
            if emitted < count {
                result[written] = ((b << 4) | (c >> 2)) as u8;
                written += 1;
                emitted += 1;
            }
            if emitted < count {
                result[written] = ((c << 6) | d) as u8;
                written += 1;
                emitted += 1;
            }
        }
        cursor += 1;
    }
    written as i64
}
