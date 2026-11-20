const MAX_INPUT: usize = 97;
const MAX_TEXT: usize = 64;
const BOARD_SIZE: usize = 30;
const MAX_OUTPUT: usize = 128;

fn parse_board(input: &[i64]) -> Option<(usize, usize, usize, i64)> {
    if input.len() < 32 || input.len() > MAX_INPUT { return None; }
    let mode = input[0];
    if mode != 0 && mode != 1 { return None; }
    let mut holes = [usize::MAX; 2];
    let mut hole_count = 0usize;
    for position in 0..BOARD_SIZE {
        let value = input[1 + position];
        if position < 10 && value == 0 {
            if hole_count >= 2 { return None; }
            holes[hole_count] = position;
            hole_count += 1;
            continue;
        }
        if !(32..=126).contains(&value) { return None; }
        for prior in 0..position {
            if input[1 + prior] == value { return None; }
        }
    }
    if hole_count != 2 { return None; }
    let text_length = input[31];
    if !(0..=MAX_TEXT as i64).contains(&text_length)
        || input.len() != 32 + text_length as usize { return None; }
    Some((holes[0], holes[1], text_length as usize, mode))
}

fn find_symbol(input: &[i64], value: i64) -> Option<usize> {
    (0..BOARD_SIZE).find(|&position| input[1 + position] != 0 && input[1 + position] == value)
}

fn measure_decode(input: &[i64], text_length: usize, hole_a: usize,
                  hole_b: usize) -> Option<usize> {
    let mut output_length = 0usize;
    let mut index = 0usize;
    while index < text_length {
        let value = input[32 + index];
        if !(b'0' as i64..=b'9' as i64).contains(&value) { return None; }
        let column = (value - b'0' as i64) as usize;
        if input[1 + column] != 0 {
            output_length += 1;
            index += 1;
            continue;
        }
        if column != hole_a && column != hole_b || index + 1 >= text_length { return None; }
        let next = input[32 + index + 1];
        if !(b'0' as i64..=b'9' as i64).contains(&next) { return None; }
        output_length += 1;
        index += 2;
    }
    Some(output_length)
}

#[no_mangle]
pub unsafe extern "C" fn straddling_checkerboard_transducer(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 32 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let Some((hole_a, hole_b, text_length, mode)) = parse_board(values) else { return -1; };

    let result_length = if mode == 0 {
        let mut total = 0usize;
        for index in 0..text_length {
            let Some(position) = find_symbol(values, values[32 + index]) else { return -1; };
            total += if position < 10 { 1 } else { 2 };
        }
        total
    } else {
        let Some(total) = measure_decode(values, text_length, hole_a, hole_b) else { return -1; };
        total
    };
    if result_length > MAX_OUTPUT { return -1; }
    if output.is_null() || output_capacity < result_length { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, result_length);

    if mode == 0 {
        let mut out = 0usize;
        for index in 0..text_length {
            let position = find_symbol(values, values[32 + index]).unwrap();
            if position < 10 {
                bytes[out] = b'0' + position as u8;
                out += 1;
            } else {
                let row_digit = if position < 20 { hole_a } else { hole_b };
                bytes[out] = b'0' + row_digit as u8;
                bytes[out + 1] = b'0' + (position % 10) as u8;
                out += 2;
            }
        }
    } else {
        let mut index = 0usize;
        let mut out = 0usize;
        while index < text_length {
            let column = (values[32 + index] - b'0' as i64) as usize;
            if values[1 + column] != 0 {
                bytes[out] = values[1 + column] as u8;
                index += 1;
            } else {
                let row = if column == hole_a { 1 } else { 2 };
                let next_column = (values[32 + index + 1] - b'0' as i64) as usize;
                bytes[out] = values[1 + row * 10 + next_column] as u8;
                index += 2;
            }
            out += 1;
        }
    }
    result_length as i64
}
