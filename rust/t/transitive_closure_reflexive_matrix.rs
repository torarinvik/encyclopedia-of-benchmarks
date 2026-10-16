const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = MAX_VERTICES * (MAX_VERTICES - 1);
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_CELLS: usize = MAX_VERTICES * MAX_VERTICES;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn transitive_closure_reflexive_matrix(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if !(1..=MAX_VERTICES as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let m_value = values[1];
    if m_value < 0 || m_value > (n * (n - 1)) as i64 { return -1; }
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }

    let mut reach = [0i64; MAX_CELLS];
    for i in 0..n { reach[i * n + i] = 1; }
    for edge in 0..m {
        let from_value = values[2 + 2 * edge];
        let to_value = values[3 + 2 * edge];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64 || from_value == to_value { return -1; }
        let from = from_value as usize;
        let to = to_value as usize;
        if reach[from * n + to] != 0 { return -1; }
        reach[from * n + to] = 1;
    }
    for k in 0..n {
        for i in 0..n {
            if reach[i * n + k] == 1 {
                for j in 0..n {
                    if reach[k * n + j] == 1 { reach[i * n + j] = 1; }
                }
            }
        }
    }

    let output_bytes = n * n * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let result = unsafe { core::slice::from_raw_parts_mut(output, output_bytes) };
    for index in 0..n * n { put_i64_le(result, index * 8, reach[index]); }
    output_bytes as i64
}
