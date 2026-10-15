/// Bounded circular buffer that overwrites the oldest item when full.
#[no_mangle]
pub unsafe extern "C" fn circular_buffer_benchmark(values: *const i64, length: usize) -> i64 {
    const MAX_CAPACITY: usize = 256;
    const OFFSET: i64 = 1_000_000;
    if values.is_null() || length < 1 || length > 1025 || (length - 1) % 2 != 0 { return -1; }
    let capacity_value = *values;
    if !(1..=MAX_CAPACITY as i64).contains(&capacity_value) { return -1; }
    let capacity = capacity_value as usize;
    let operation_count = (length - 1) / 2;
    let mut buffer = [0_i64; MAX_CAPACITY];
    let mut head = 0;
    let mut tail = 0;
    let mut count = 0;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(1 + 2 * operation);
        let payload = *values.add(2 + 2 * operation);
        let observed;
        if opcode == 0 {
            if !(0..=OFFSET).contains(&payload) { return -1; }
            let was_empty = count == 0;
            if count == capacity { head = (head + 1) % capacity; } else { count += 1; }
            buffer[tail] = payload;
            tail = (tail + 1) % capacity;
            observed = i64::from(was_empty);
        } else if opcode == 1 {
            if payload != 0 { return -1; }
            if count == 0 { observed = -1; }
            else {
                observed = buffer[head];
                head = (head + 1) % capacity;
                count -= 1;
            }
        } else if opcode == 2 {
            if payload != 0 { return -1; }
            observed = i64::from(count == 0);
        } else if opcode == 3 {
            if payload != 0 { return -1; }
            observed = i64::from(count == capacity);
        } else if opcode == 4 {
            if payload != 0 { return -1; }
            observed = count as i64;
        } else { return -1; }
        checksum += (operation as i64 + 1) * (observed + OFFSET);
    }
    for index in 0..count {
        checksum += (operation_count as i64 + index as i64 + 1)
            * (buffer[(head + index) % capacity] + OFFSET);
    }
    checksum
}
