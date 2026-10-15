use core::slice;

unsafe fn append_u64(mut value: u64, output: *mut u8, capacity: usize, position: &mut usize) -> bool {
    let mut digits = [0u8; 20];
    let mut count = 0usize;
    loop {
        digits[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    if count > capacity - *position { return false; }
    while count != 0 {
        count -= 1;
        *output.add(*position) = digits[count];
        *position += 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn allocation_number(values: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if length != 2 { return -1; }
    let values = slice::from_raw_parts(values, length);
    if values[0] < 1 || values[0] > 1_000_000 || values[1] < 1 || values[1] > 128 || values[1] > values[0] { return -1; }
    let total = values[0] as u64;
    let partitions = values[1] as u64;
    let block = total / partitions;
    let mut position = 0usize;
    for index in 0..partitions {
        let start = index * block + 1;
        let end = if index + 1 == partitions { total } else { (index + 1) * block };
        if !append_u64(start, output, output_capacity, &mut position) { return -2; }
        if position >= output_capacity { return -2; }
        *output.add(position) = b'-';
        position += 1;
        if !append_u64(end, output, output_capacity, &mut position) { return -2; }
        if index + 1 != partitions {
            if position >= output_capacity { return -2; }
            *output.add(position) = b',';
            position += 1;
        }
    }
    position as i64
}
