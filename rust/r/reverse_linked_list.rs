const MAX_N: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_N + 1;

#[no_mangle]
pub unsafe extern "C" fn reverse_linked_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    if length != n + 1 { return -1; }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut nodes = [0i64; MAX_N];
    let mut next = [-1i32; MAX_N];
    let mut previous_link = [-1i32; MAX_N];
    for i in 0..n {
        nodes[i] = values[i + 1];
        next[i] = if i + 1 < n { (i + 1) as i32 } else { -1 };
        previous_link[i] = if i > 0 { (i - 1) as i32 } else { -1 };
    }
    let (mut previous, mut current) = (-1i32, 0i32);
    while current >= 0 {
        let next_node = next[current as usize];
        next[current as usize] = previous;
        previous_link[current as usize] = next_node;
        previous = current;
        current = next_node;
    }
    let mut node = previous;
    let mut expected_previous = -1i32;
    let mut result = [0i64; MAX_N];
    for i in 0..n {
        if node < 0 || previous_link[node as usize] != expected_previous { return -1; }
        result[i] = nodes[node as usize] as i64;
        expected_previous = node;
        node = next[node as usize];
    }
    if node >= 0 { return -1; }
    for i in 0..n {
        std::ptr::copy_nonoverlapping(result[i].to_le_bytes().as_ptr(), output.add(i * 8), 8);
    }
    output_bytes as i64
}
