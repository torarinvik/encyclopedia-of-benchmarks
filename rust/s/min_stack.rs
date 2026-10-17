const MAX_OPERATIONS: usize = 256;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = (1 + 3 * MAX_OPERATIONS) * 8;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn min_stack(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_VALUES).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_OPERATIONS as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;

    let mut opcodes = [0i64; MAX_OPERATIONS];
    let mut operands = [0i64; MAX_OPERATIONS];
    let mut position = 1usize;
    let mut query_count = 0usize;
    for index in 0..count {
        if position >= length { return -1; }
        let opcode = values[position];
        position += 1;
        let mut operand = 0i64;
        if opcode == 0 {
            if position >= length { return -1; }
            operand = values[position];
            position += 1;
            if operand < i32::MIN as i64 || operand > i32::MAX as i64 { return -1; }
        } else if opcode == 2 || opcode == 3 {
            query_count += 1;
        } else if opcode != 1 {
            return -1;
        }
        opcodes[index] = opcode;
        operands[index] = operand;
    }
    if position != length { return -1; }

    let needed = (1 + 3 * query_count) * 8;
    if output.is_null() || capacity < needed { return -2; }

    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    write_i64_le(&mut buffer, 0, query_count as i64);
    let mut stack_values = [0i64; MAX_OPERATIONS];
    let mut stack_minima = [0i64; MAX_OPERATIONS];
    let mut depth = 0usize;
    let mut record = 1usize;
    for index in 0..count {
        let opcode = opcodes[index];
        if opcode == 0 {
            let value = operands[index];
            stack_values[depth] = value;
            stack_minima[depth] = if depth == 0 || value < stack_minima[depth - 1] {
                value
            } else {
                stack_minima[depth - 1]
            };
            depth += 1;
        } else if opcode == 1 {
            if depth > 0 { depth -= 1; }
        } else {
            let (exception_flag, value) = if depth == 0 {
                (1, 0)
            } else if opcode == 2 {
                (0, stack_values[depth - 1])
            } else {
                (0, stack_minima[depth - 1])
            };
            write_i64_le(&mut buffer, record * 8, opcode);
            write_i64_le(&mut buffer, (record + 1) * 8, exception_flag);
            write_i64_le(&mut buffer, (record + 2) * 8, value);
            record += 3;
        }
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, needed);
    needed as i64
}
