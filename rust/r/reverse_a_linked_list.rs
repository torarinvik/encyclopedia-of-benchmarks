const MAX_N: usize = 128;
const MAX_INPUT_LENGTH: usize = MAX_N + 1;

#[no_mangle]
pub unsafe extern "C" fn reverse_a_linked_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 0 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    if length != n + 1 || values[1..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) { return -1; }
    let output_bytes = 4 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut nodes = [0i32; MAX_N];
    let mut next = [-1i32; MAX_N];
    let mut head = -1i32;
    for i in 0..n {
        nodes[i] = values[i + 1] as i32;
        next[i] = -1;
        if head < 0 { head = i as i32; }
        else {
            let mut tail = head;
            while next[tail as usize] >= 0 { tail = next[tail as usize]; }
            next[tail as usize] = i as i32;
        }
    }
    let (mut previous, mut current) = (-1i32, head);
    while current >= 0 {
        let next_node = next[current as usize];
        next[current as usize] = previous;
        previous = current;
        current = next_node;
    }
    head = previous;
    for index in 0..n {
        let mut node = head;
        for _ in 0..index { node = next[node as usize]; }
        let bits = nodes[node as usize] as u32;
        for byte in 0..4 { *output.add(index * 4 + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
