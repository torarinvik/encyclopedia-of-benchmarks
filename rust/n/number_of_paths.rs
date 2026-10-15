/// Count vertex-simple directed paths with recursive DFS.
fn count_from(matrix: &[i64], n: usize, current: usize, destination: usize, visited: u32) -> u32 {
    if current == destination { return 1; }
    let seen = visited | (1u32 << current);
    let mut count = 0u32;
    for next in 0..n {
        if matrix[current * n + next] == 1 && (seen & (1u32 << next)) == 0 {
            count += count_from(matrix, n, next, destination, seen);
        }
    }
    count
}

#[no_mangle]
pub extern "C" fn number_of_paths(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=10).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 3 + n * n { return -1; }
    if values[1] < 0 || values[1] > u32::MAX as i64 || values[2] < 0 || values[2] > u32::MAX as i64 {
        return -1;
    }
    if values[3..].iter().any(|&cell| cell != 0 && cell != 1) { return -1; }
    let source = values[1] as usize;
    let destination = values[2] as usize;
    if source >= n || destination >= n { return 0; }
    count_from(&values[3..], n, source, destination, 0) as i64
}
