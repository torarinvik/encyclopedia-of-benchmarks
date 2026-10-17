const MAX_N: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_N + 2;

#[no_mangle]
pub unsafe extern "C" fn reverse_k_group(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, k_value) = (values[0], values[1]);
    if !(0..=MAX_N as i64).contains(&n_value) || !(1..=MAX_N as i64).contains(&k_value) { return -1; }
    let (n, k) = (n_value as usize, k_value as usize);
    if length != n + 2 { return -1; }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut nodes = [0i64; MAX_N];
    let mut next = [-1i32; MAX_N + 1];
    let mut head = -1i32;
    for i in 0..n {
        nodes[i] = values[i + 2];
        next[i] = -1;
        if head < 0 { head = i as i32; }
        else {
            let mut tail = head;
            while next[tail as usize] >= 0 { tail = next[tail as usize]; }
            next[tail as usize] = i as i32;
        }
    }
    let mut remaining = 0usize;
    let mut node = head;
    while node >= 0 { remaining += 1; node = next[node as usize]; }
    let dummy = MAX_N;
    next[dummy] = head;
    let mut previous = dummy as i32;
    while remaining >= k {
        let current = next[previous as usize];
        let mut moved = next[current as usize];
        for _ in 1..k {
            next[current as usize] = next[moved as usize];
            next[moved as usize] = next[previous as usize];
            next[previous as usize] = moved;
            moved = next[current as usize];
        }
        previous = current;
        remaining -= k;
    }

    let mut result = [0i64; MAX_N];
    let mut index = 0;
    node = next[dummy];
    while node >= 0 {
        result[index] = nodes[node as usize];
        index += 1;
        node = next[node as usize];
    }
    for i in 0..n {
        std::ptr::copy_nonoverlapping(result[i].to_le_bytes().as_ptr(), output.add(i * 8), 8);
    }
    output_bytes as i64
}
