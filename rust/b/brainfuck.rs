/// Interpret a bounded Brainfuck byte program with portable limits.
#[no_mangle]
pub extern "C" fn brainfuck(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    const MAX_PROGRAM: usize = 2048;
    const MAX_INPUT: usize = 1024;
    const MAX_OUTPUT: usize = 8192;
    const MAX_STEPS: usize = 100_000;
    const TAPE_CELLS: usize = 257;

    if values.is_null() || length < 2 || length > MAX_PROGRAM + MAX_INPUT + 2 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_PROGRAM as i64).contains(&values[0]) { return -2; }
    let program_length = values[0] as usize;
    let input_length_index = program_length + 1;
    if input_length_index >= length || !(0..=MAX_INPUT as i64).contains(&values[input_length_index]) {
        return -2;
    }
    let input_length = values[input_length_index] as usize;
    if length != program_length + input_length + 2 { return -2; }

    let mut matching = [ -1_i32; MAX_PROGRAM ];
    let mut openings = [ 0_usize; MAX_PROGRAM ];
    for index in 0..program_length {
        let byte = values[index + 1];
        if !(32..=126).contains(&byte) { return -2; }
    }
    let mut depth = 0;
    for index in 0..program_length {
        match values[index + 1] {
            91 => openings[depth] = index,
            93 => {
                if depth == 0 { return -2; }
                depth -= 1;
                let opening = openings[depth];
                matching[opening] = index as i32;
                matching[index] = opening as i32;
            }
            _ => {}
        }
        if values[index + 1] == 91 { depth += 1; }
    }
    if depth != 0 { return -2; }
    for index in 0..input_length {
        if !(0..=255).contains(&values[input_length_index + 1 + index]) { return -2; }
    }

    let mut tape = [0_u8; TAPE_CELLS];
    let mut scratch = [0_u8; MAX_OUTPUT];
    let mut data_pointer = TAPE_CELLS / 2;
    let mut input_index = 0;
    let mut instruction = 0;
    let mut steps = 0;
    let mut output_length = 0;
    while instruction < program_length {
        steps += 1;
        if steps > MAX_STEPS { return -2; }
        match values[instruction + 1] {
            46 => {
                if output_length == MAX_OUTPUT { return -2; }
                scratch[output_length] = tape[data_pointer];
                output_length += 1;
            }
            44 => {
                tape[data_pointer] = if input_index < input_length {
                    let value = values[input_length_index + 1 + input_index] as u8;
                    input_index += 1;
                    value
                } else { 0 };
            }
            62 => {
                data_pointer += 1;
                if data_pointer >= TAPE_CELLS { return -2; }
            }
            60 => {
                if data_pointer == 0 { return -2; }
                data_pointer -= 1;
            }
            43 => tape[data_pointer] = tape[data_pointer].wrapping_add(1),
            45 => tape[data_pointer] = tape[data_pointer].wrapping_sub(1),
            91 if tape[data_pointer] == 0 => instruction = matching[instruction] as usize,
            93 if tape[data_pointer] != 0 => instruction = matching[instruction] as usize,
            _ => {}
        }
        instruction += 1;
    }
    if output_length > output_capacity || (output_length != 0 && output.is_null()) { return -2; }
    if output_length != 0 {
        unsafe { std::ptr::copy_nonoverlapping(scratch.as_ptr(), output, output_length); }
    }
    output_length as i64
}
