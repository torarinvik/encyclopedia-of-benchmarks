const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;
const MAX_OUTPUT_BYTES: usize = 1536;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn write_record(output: &mut [u8], offset: usize, opcode: i64, tag: i64, value: i64) {
    write_i64_le(output, offset, opcode);
    write_i64_le(output, offset + 8, tag);
    write_i64_le(output, offset + 16, value);
}

#[no_mangle]
pub unsafe extern "C" fn stack_with_singly_linked_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    let mut opcodes = [0i64; MAX_OPERATIONS];
    let mut arguments = [0i64; MAX_OPERATIONS];
    let mut cursor = 1usize;
    for i in 0..count {
        if cursor >= length { return -1; }
        let opcode = values[cursor];
        cursor += 1;
        opcodes[i] = opcode;
        if opcode == 1 {
            if cursor >= length { return -1; }
            let value = values[cursor];
            cursor += 1;
            if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
            arguments[i] = value;
        } else if !(2..=5).contains(&opcode) { return -1; }
    }
    if cursor != length { return -1; }

    let mut node_values = [0i64; MAX_OPERATIONS + 1];
    let mut next_ids = [0usize; MAX_OPERATIONS + 1];
    let mut node_count = 0usize;
    let mut head = 0usize;
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    for i in 0..count {
        let opcode = opcodes[i];
        let (mut tag, mut value) = (2i64, 0i64);
        if opcode == 1 {
            node_count += 1;
            node_values[node_count] = arguments[i];
            next_ids[node_count] = head;
            head = node_count;
        } else if opcode == 2 || opcode == 3 {
            if head == 0 {
                write_record(&mut buffer, written, opcode, 4, 2);
                written += 24;
                break;
            }
            tag = 0;
            value = node_values[head];
            if opcode == 2 { head = next_ids[head]; }
        } else if opcode == 4 {
            head = 0;
        } else {
            tag = 0;
            let mut node = head;
            while node != 0 { value += 1; node = next_ids[node]; }
        }
        write_record(&mut buffer, written, opcode, tag, value);
        written += 24;
    }
    if output.is_null() || capacity < written { return -2; }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, written);
    written as i64
}
