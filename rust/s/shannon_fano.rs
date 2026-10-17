const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_SYMBOLS: usize = 10;
const MAX_CODE_LENGTH: usize = 9;
const MAX_OUTPUT_BYTES: usize = 111;

#[derive(Clone, Copy)]
struct Frame { start: usize, end: usize, bits: u16, length: usize }

/// Generate and canonically serialize the pinned Shannon–Fano code map.
#[no_mangle]
pub unsafe extern "C" fn shannon_fano_generate_codes(input: *const i64, input_length: usize,
                                                        output: *mut u8, output_capacity: usize) -> i64 {
    let is_null_empty = input.is_null() && input_length == 0;
    if input.is_null() && !is_null_empty { return -1; }
    let mut text = [0_u8; MAX_TEXT_LENGTH];
    let mut text_length = 0_usize;
    if !is_null_empty {
        if !(1..=MAX_INPUT_LENGTH).contains(&input_length) { return -1; }
        let length_value = unsafe { *input };
        if !(0..=MAX_TEXT_LENGTH as i64).contains(&length_value) { return -1; }
        text_length = length_value as usize;
        if input_length != 1 + text_length { return -1; }
        for index in 0..text_length {
            let code = unsafe { *input.add(1 + index) };
            if !(0..=127).contains(&code) { return -1; }
            text[index] = code as u8;
        }
    }

    let mut frequencies = [0_usize; 128];
    for &symbol in &text[..text_length] { frequencies[symbol as usize] += 1; }
    let mut symbols = [0_usize; 128];
    let mut symbol_count = 0_usize;
    for symbol in 0..128 {
        if frequencies[symbol] != 0 {
            symbols[symbol_count] = symbol;
            symbol_count += 1;
        }
    }
    if symbol_count > MAX_SYMBOLS { return -1; }
    for left in 0..symbol_count {
        for right in left + 1..symbol_count {
            if frequencies[symbols[left]] == frequencies[symbols[right]] { return -1; }
        }
    }
    for index in 1..symbol_count {
        let value = symbols[index];
        let mut position = index;
        while position > 0 && frequencies[symbols[position - 1]] < frequencies[value] {
            symbols[position] = symbols[position - 1];
            position -= 1;
        }
        symbols[position] = value;
    }

    let mut code_bits = [0_u16; 128];
    let mut code_lengths = [0_usize; 128];
    if symbol_count == 1 {
        code_lengths[symbols[0]] = 1;
    } else if symbol_count > 1 {
        let mut stack = [Frame { start: 0, end: 0, bits: 0, length: 0 }; 20];
        let mut stack_length = 1_usize;
        stack[0] = Frame { start: 0, end: symbol_count - 1, bits: 0, length: 0 };
        while stack_length > 0 {
            stack_length -= 1;
            let frame = stack[stack_length];
            if frame.start == frame.end {
                let symbol = symbols[frame.start];
                code_bits[symbol] = frame.bits;
                code_lengths[symbol] = frame.length;
                continue;
            }
            let mut total = 0_usize;
            for index in frame.start..=frame.end { total += frequencies[symbols[index]]; }
            let mut left_sum = 0_usize;
            let mut best_difference = usize::MAX;
            let mut split = frame.start;
            for index in frame.start..frame.end {
                left_sum += frequencies[symbols[index]];
                let right_sum = total - left_sum;
                let difference = left_sum.abs_diff(right_sum);
                if difference < best_difference {
                    best_difference = difference;
                    split = index;
                }
            }
            let next_length = frame.length + 1;
            stack[stack_length] = Frame { start: split + 1, end: frame.end,
                bits: (frame.bits << 1) | 1, length: next_length };
            stack_length += 1;
            stack[stack_length] = Frame { start: frame.start, end: split,
                bits: frame.bits << 1, length: next_length };
            stack_length += 1;
        }
    }

    let mut bytes = [0_u8; MAX_OUTPUT_BYTES];
    let mut written = 0_usize;
    bytes[written] = symbol_count as u8;
    written += 1;
    for symbol in 0..128 {
        let length = code_lengths[symbol];
        if length == 0 { continue; }
        bytes[written] = symbol as u8;
        bytes[written + 1] = length as u8;
        written += 2;
        for offset in 0..length {
            let bit = (code_bits[symbol] >> (length - 1 - offset)) & 1;
            bytes[written] = b'0' + bit as u8;
            written += 1;
        }
    }
    if output.is_null() || output_capacity < written { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, written); }
    written as i64
}
