const MAX_OPS: usize = 128;

fn push_new(main: &mut [i64; MAX_OPS], temp: &mut [i64; MAX_OPS],
            head: &mut usize, tail: &mut usize, value: i64) {
    let mut temp_tail = 0;
    temp[temp_tail] = value;
    temp_tail += 1;
    while *head < *tail {
        temp[temp_tail] = main[*head];
        temp_tail += 1;
        *head += 1;
    }
    *head = 0;
    *tail = temp_tail;
}

#[no_mangle]
pub extern "C" fn stack_using_two_queues(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 257 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    if a[0] < 0 || a[0] > MAX_OPS as i64 || length != 1 + 2 * a[0] as usize { return -1; }
    let (mut qa, mut qb) = ([0i64; MAX_OPS], [0i64; MAX_OPS]);
    let (mut main_is_a, mut head, mut tail) = (true, 0usize, 0usize);
    let mut tags = [0i64; MAX_OPS];
    let mut results = [0i64; MAX_OPS];
    let mut record_count = 0usize;
    let mut pos = 1usize;
    for _ in 0..a[0] as usize {
        let op = a[pos];
        let value = a[pos + 1];
        pos += 2;
        if op == 0 {
            if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
            if main_is_a { push_new(&mut qa, &mut qb, &mut head, &mut tail, value); }
            else { push_new(&mut qb, &mut qa, &mut head, &mut tail, value); }
            main_is_a = !main_is_a;
        } else if op == 1 {
            if value != 0 || head == tail { return -1; }
            tags[record_count] = 0;
            results[record_count] = if main_is_a { qa[head] } else { qb[head] };
            record_count += 1;
            head += 1;
        } else if op == 2 {
            if value != 0 { return -1; }
            if head == tail { tags[record_count] = 1; results[record_count] = 0; }
            else { tags[record_count] = 0; results[record_count] = if main_is_a { qa[head] } else { qb[head] }; }
            record_count += 1;
        } else { return -1; }
    }
    let bytes = record_count * 16;
    if output.is_null() || output_capacity < bytes { return -2; }
    unsafe {
        for i in 0..record_count {
            for (word, value) in [tags[i], results[i]].iter().enumerate() {
                for b in 0..8 { *output.add(16*i+8*word+b) = ((*value as u64) >> (8*b)) as u8; }
            }
        }
    }
    bytes as i64
}
