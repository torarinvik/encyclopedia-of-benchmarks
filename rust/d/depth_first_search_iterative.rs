const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 256;
const MAX_INPUT_LENGTH: usize = 518;
#[no_mangle]
pub unsafe extern "C" fn depth_first_search_iterative(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    let m = values[1];
    let source = values[2];
    let target = values[3];
    if n < 1 || n > MAX_VERTICES as i64 || m < 0 || m > MAX_EDGES || source < 0 || source >= n
        { return -1; }
    let edge_count = m as usize;
    if length != 4 + 2 * edge_count { return -1; }
    for edge in 0..edge_count {
        let left = values[4 + 2 * edge];
        let right = values[5 + 2 * edge];
        if left < 0 || left >= n || right < 0 || right >= n { return -1; }
    }
    let mut visited = [false; MAX_VERTICES];
    let mut pending = [0usize; MAX_VERTICES];
    let mut top = 1usize;
    pending[0] = source as usize;
    visited[pending[0]] = true;
    while top > 0 {
        top -= 1;
        let current = pending[top];
        if current as i64 == target { return 1; }
        for edge in 0..edge_count {
            let left = values[4 + 2 * edge];
            let right = values[5 + 2 * edge];
            let neighbor = if left == current as i64 { right } else if right == current as i64 { left } else { -1 };
            if neighbor >= 0 {
                let index = neighbor as usize;
                if !visited[index] {
                    visited[index] = true;
                    pending[top] = index;
                    top += 1;
                }
            }
        }
    }
    0
}
