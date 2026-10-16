const MAX_Q: usize = 512;

#[no_mangle]
pub extern "C" fn queue_using_array(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 || length > 1 + 2 * MAX_Q { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let qv = packed[0];
    if !(0..=MAX_Q as i64).contains(&qv) || length != 1 + qv as usize * 2 { return -1; }
    let q = qv as usize;
    for i in 0..q {
        let (op, value) = (packed[1 + i * 2], packed[2 + i * 2]);
        if op == 0 { if !(-128..=127).contains(&value) { return -1; } }
        else if op == 1 { if value != 0 { return -1; } }
        else { return -1; }
    }
    let mut values = [0i16; 10];
    let (mut front, mut rear) = (-1i32, -1i32);
    let (mut checksum, mut ordinal) = (0i64, 0i64);
    for i in 0..q {
        let op = packed[1 + i * 2];
        let value = packed[2 + i * 2];
        if op == 0 {
            if rear == 9 { continue; }
            if front == -1 && rear == -1 { front = 0; rear = 0; values[0] = value as i16; }
            else if rear < 10 { rear += 1; values[rear as usize] = value as i16; }
        } else {
            let mut dequeued = 0i64;
            if front != -1 {
                if front == rear { dequeued = values[front as usize] as i8 as i64; front = -1; rear = -1; }
                else { dequeued = values[front as usize] as i8 as i64; front += 1; }
            }
            ordinal += 1;
            checksum += ordinal * (dequeued + 128);
        }
    }
    checksum
}
