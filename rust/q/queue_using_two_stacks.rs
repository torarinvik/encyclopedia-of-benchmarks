/// Amortized FIFO queue implemented with an input and an output stack.
#[no_mangle]
pub unsafe extern "C" fn queue_using_two_stacks_benchmark(values: *const i64, length: usize) -> i64 {
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut in_stack = [0_i64; 256];
    let mut out_stack = [0_i64; 256];
    let mut in_count = 0;
    let mut out_count = 0;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        let mut returns_value = true;
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&payload) || in_count + out_count == 256 { return -1; }
            in_stack[in_count] = payload;
            in_count += 1;
            returns_value = false;
        } else if opcode == 1 || opcode == 2 {
            if payload != 0 { return -1; }
            if out_count == 0 {
                while in_count > 0 {
                    in_count -= 1;
                    out_stack[out_count] = in_stack[in_count];
                    out_count += 1;
                }
            }
            if out_count == 0 { return -1; }
            if opcode == 1 {
                out_count -= 1;
                observed = out_stack[out_count];
            } else {
                observed = out_stack[out_count - 1];
            }
        } else if opcode == 3 {
            if payload != 0 { return -1; }
            observed = i64::from(in_count + out_count == 0);
        } else if opcode == 4 {
            if payload != 0 { return -1; }
            observed = (in_count + out_count) as i64;
        } else { return -1; }
        if returns_value { checksum += (operation as i64 + 1) * (observed + 1_000_000); }
    }
    for index in 0..out_count {
        checksum += (operation_count as i64 + index as i64 + 1)
            * (out_stack[out_count - index - 1] + 1_000_000);
    }
    for index in 0..in_count {
        checksum += (operation_count as i64 + out_count as i64 + index as i64 + 1)
            * (in_stack[index] + 1_000_000);
    }
    checksum
}
