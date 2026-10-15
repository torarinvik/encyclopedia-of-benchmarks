/// Baconian cipher with explicit Java, Python, and Rust source dialects.
const MAX_PAYLOAD: usize = 1024;

fn python_code_for_letter(upper: i64) -> i64 {
    if upper >= 65 && upper <= 73 { return upper - 65; }
    if upper == b'J' as i64 { return 28; }
    if upper >= 75 && upper <= 85 { return upper - 66; }
    if upper == b'V' as i64 { return 29; }
    if upper >= 87 && upper <= 90 { return upper - 67; }
    -1
}

fn python_letter_for_code(code: i64) -> i64 {
    if (0..=8).contains(&code) { return b'a' as i64 + code; }
    if code == 28 { return b'j' as i64; }
    if code == 29 { return b'v' as i64; }
    if (9..=19).contains(&code) { return b'a' as i64 + code + 1; }
    if (20..=23).contains(&code) { return b'a' as i64 + code + 2; }
    -1
}

unsafe fn decode_code(payload: *const i64, start: usize) -> i64 {
    let mut code = 0;
    for bit in 0..5 { code = (code << 1) | (*payload.add(start + bit) == b'B' as i64) as i64; }
    code
}

unsafe fn write_code(output: *mut u8, position: &mut usize, code: i64) {
    for bit in (0..5).rev() {
        *output.add(*position) = if (code >> bit) & 1 != 0 { b'B' } else { b'A' };
        *position += 1;
    }
}

unsafe fn python_decode_length(payload: *const i64, n: usize) -> Option<usize> {
    let mut words = 0usize;
    let mut letters = 0usize;
    let mut used = 0usize;
    let mut code = 0i64;
    let mut in_word = false;
    for i in 0..n {
        let value = *payload.add(i);
        if value == b' ' as i64 {
            if used != 0 { return None; }
            if in_word { words += 1; in_word = false; }
        } else {
            if value != b'A' as i64 && value != b'B' as i64 { return None; }
            in_word = true;
            code = (code << 1) | (value == b'B' as i64) as i64;
            used += 1;
            if used == 5 {
                if python_letter_for_code(code) < 0 { return None; }
                letters += 1;
                used = 0;
                code = 0;
            }
        }
    }
    if used != 0 { return None; }
    if in_word { words += 1; }
    Some(letters + words.saturating_sub(1))
}

#[no_mangle]
pub unsafe extern "C" fn baconian_cipher(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PAYLOAD + 2 { return -1; }
    let mode = *values;
    let dialect = *values.add(1);
    if (mode != 0 && mode != 1) || !(0..=2).contains(&dialect) { return -1; }
    let n = length - 2;
    let payload = values.add(2);
    for i in 0..n { if ! (0..=127).contains(&*payload.add(i)) { return -1; } }

    let mut output_length = 0usize;
    if mode == 0 {
        for i in 0..n {
            let value = *payload.add(i);
            let upper = if value >= 97 && value <= 122 { value - 32 } else { value };
            let is_letter = upper >= 65 && upper <= 90;
            if dialect == 0 { if is_letter { output_length += 5; } }
            else if dialect == 1 {
                if value == b' ' as i64 { output_length += 1; }
                else if is_letter { output_length += 5; }
                else { return -1; }
            } else if is_letter {
                if upper > b'X' as i64 { return -1; }
                output_length += 5;
            } else { output_length += 1; }
        }
    } else if dialect == 0 {
        if n % 5 != 0 { return -1; }
        for i in 0..n { let v = *payload.add(i); if v != b'A' as i64 && v != b'B' as i64 { return -1; } }
        for i in (0..n).step_by(5) { if decode_code(payload, i) > 25 { return -1; } }
        output_length = n / 5;
    } else if dialect == 1 {
        match python_decode_length(payload, n) { Some(size) => output_length = size, None => return -1 }
    } else { output_length = (n + 4) / 5; }
    if output_capacity < output_length || (output_length > 0 && output.is_null()) { return -2; }

    let mut write = 0usize;
    if mode == 0 {
        for i in 0..n {
            let value = *payload.add(i);
            let upper = if value >= 97 && value <= 122 { value - 32 } else { value };
            if dialect == 0 {
                if upper >= 65 && upper <= 90 { write_code(output, &mut write, if upper == 73 { 9 } else { upper - 65 }); }
            } else if dialect == 1 {
                if value == b' ' as i64 { *output.add(write) = b' '; write += 1; }
                else { write_code(output, &mut write, python_code_for_letter(upper)); }
            } else if upper >= 65 && upper <= 90 {
                write_code(output, &mut write, upper - 65);
            } else { *output.add(write) = value as u8; write += 1; }
        }
    } else if dialect == 0 {
        for i in (0..n).step_by(5) {
            let code = decode_code(payload, i);
            *output.add(write) = if code == 8 || code == 9 { b'I' } else { (b'A' as i64 + code) as u8 };
            write += 1;
        }
    } else if dialect == 1 {
        let mut i = 0usize;
        let mut first_word = true;
        while i < n {
            while i < n && *payload.add(i) == b' ' as i64 { i += 1; }
            if i == n { break; }
            if !first_word { *output.add(write) = b' '; write += 1; }
            first_word = false;
            while i < n && *payload.add(i) != b' ' as i64 {
                *output.add(write) = python_letter_for_code(decode_code(payload, i)) as u8;
                write += 1; i += 5;
            }
        }
    } else {
        for i in (0..n).step_by(5) {
            if n - i < 5 { *output.add(write) = b' '; write += 1; continue; }
            let mut code = 0i64; let mut valid = true;
            for bit in 0..5 {
                let value = *payload.add(i + bit);
                if value != b'A' as i64 && value != b'B' as i64 { valid = false; }
                code = (code << 1) | (value == b'B' as i64) as i64;
            }
            *output.add(write) = if valid && code < 24 { (b'A' as i64 + code) as u8 } else { b' ' };
            write += 1;
        }
    }
    output_length as i64
}
