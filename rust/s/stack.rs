/// Bounded array-backed integer stack with a deterministic operation-trace checksum.
#[no_mangle]
pub unsafe extern "C" fn stack_benchmark(values: *const i64, length: usize) -> i64 {
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut data_stack = [0_i64; 256];
    let mut top = 0;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        let mut returns_value = true;
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&payload) || top == 256 { return -1; }
            data_stack[top] = payload;
            top += 1;
            returns_value = false;
        } else if opcode == 1 {
            if payload != 0 || top == 0 { return -1; }
            top -= 1;
            observed = data_stack[top];
        } else if opcode == 2 {
            if payload != 0 || top == 0 { return -1; }
            observed = data_stack[top - 1];
        } else if opcode == 3 {
            if payload != 0 { return -1; }
            observed = i64::from(top == 0);
        } else { return -1; }
        if returns_value { checksum += (operation as i64 + 1) * (observed + 1_000_000); }
    }
    for index in 0..top {
        checksum += (operation_count as i64 + index as i64 + 1)
            * (data_stack[index] + 1_000_000);
    }
    checksum
}
