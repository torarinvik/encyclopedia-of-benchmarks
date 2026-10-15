/// Check whether a root-to-leaf path has the requested sum.
fn path_has_sum(input: &[i64], node: usize, sum: i64, target: i64) -> bool {
    let base = 2 + 3 * node;
    let next_sum = sum + input[base];
    let left = input[base + 1];
    let right = input[base + 2];
    if left == -1 && right == -1 { return next_sum == target; }
    (left != -1 && path_has_sum(input, left as usize, next_sum, target)) ||
        (right != -1 && path_has_sum(input, right as usize, next_sum, target))
}

#[no_mangle]
pub extern "C" fn path_sum(input: *const i64, length: usize) -> i64 {
    if length < 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[1] < 0 || input[1] > 63 { return -1; }
    let count = input[1] as usize;
    if length != 2 + 3 * count { return -1; }
    if count == 0 { return 0; }
    for index in 0..count {
        let base = 2 + 3 * index;
        if !(-2147483648..=2147483647).contains(&input[base]) { return -1; }
        for edge in 1..=2 {
            if input[base + edge] < -1 || input[base + edge] >= count as i64 { return -1; }
        }
    }
    let mut seen = [false; 63];
    let mut stack = [0usize; 63];
    let (mut top, mut visited) = (1usize, 0usize);
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if seen[node] { return -1; }
        seen[node] = true;
        visited += 1;
        let base = 2 + 3 * node;
        let left = input[base + 1];
        let right = input[base + 2];
        if left != -1 { stack[top] = left as usize; top += 1; }
        if right != -1 { stack[top] = right as usize; top += 1; }
    }
    if visited != count { return -1; }
    if path_has_sum(input, 0, 0, input[0]) { 1 } else { 0 }
}
