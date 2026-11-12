const MAX_N: usize = 64;
const MAX_INPUT: usize = MAX_N + 2;
const MAX_WEIGHT: i64 = 1_000_000;
const INFINITY: i64 = 1i64 << 62;

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn garsia_wachs_alphabetic_tree(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    let n_value = input[0];
    if !(1..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if input_length != n + 1 || input[1..].iter().any(|&w| !(0..=MAX_WEIGHT).contains(&w)) { return -1; }

    let mut node_weight = [0i64; 2 * MAX_N - 1];
    let mut left = [-1i32; 2 * MAX_N - 1];
    let mut right = [-1i32; 2 * MAX_N - 1];
    let mut active = [0usize; MAX_N];
    for i in 0..n { node_weight[i] = input[i + 1]; active[i] = i; }
    let mut active_count = n;
    let mut next_node = n;
    while active_count > 1 {
        let mut pair = 0usize;
        while pair + 1 < active_count {
            let following = if pair + 2 < active_count { node_weight[active[pair + 2]] } else { INFINITY };
            if node_weight[active[pair]] <= following { break; }
            pair += 1;
        }
        let first = active[pair];
        let second = active[pair + 1];
        let combined = node_weight[first] + node_weight[second];
        node_weight[next_node] = combined;
        left[next_node] = first as i32;
        right[next_node] = second as i32;
        let mut earlier = pair;
        while earlier > 0 && node_weight[active[earlier - 1]] < combined { earlier -= 1; }
        let insert_at = earlier;
        for i in pair..(active_count - 2) { active[i] = active[i + 2]; }
        active_count -= 2;
        for i in (insert_at..active_count).rev() { active[i + 1] = active[i]; }
        active[insert_at] = next_node;
        active_count += 1;
        next_node += 1;
    }

    let mut depths = [0i32; MAX_N];
    let mut stack_node = [0usize; 2 * MAX_N];
    let mut stack_depth = [0i32; 2 * MAX_N];
    let mut top = 1usize;
    stack_node[0] = active[0];
    while top > 0 {
        top -= 1;
        let node = stack_node[top];
        let depth = stack_depth[top];
        if node < n { depths[node] = depth; }
        else {
            stack_node[top] = right[node] as usize;
            stack_depth[top] = depth + 1;
            top += 1;
            stack_node[top] = left[node] as usize;
            stack_depth[top] = depth + 1;
            top += 1;
        }
    }

    let mut ordered_left = [-1i32; 2 * MAX_N - 1];
    let mut ordered_right = [-1i32; 2 * MAX_N - 1];
    let mut code_node = [0usize; 2 * MAX_N];
    let mut code_depth = [0i32; 2 * MAX_N];
    let mut code_top = 0usize;
    let mut next_ordered = n;
    for leaf in 0..n {
        code_node[code_top] = leaf;
        code_depth[code_top] = depths[leaf];
        code_top += 1;
        while code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2] {
            let level = code_depth[code_top - 1];
            if level <= 0 || next_ordered >= 2 * n - 1 { return -1; }
            ordered_left[next_ordered] = code_node[code_top - 2] as i32;
            ordered_right[next_ordered] = code_node[code_top - 1] as i32;
            code_top -= 2;
            code_node[code_top] = next_ordered;
            code_depth[code_top] = level - 1;
            code_top += 1;
            next_ordered += 1;
        }
    }
    if code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1 { return -1; }
    let mut cost = 0i64;
    for i in 0..n { cost += input[i + 1] * depths[i] as i64; }
    let output_bytes = 8 * (n + 1);
    if output.is_null() || output_capacity < output_bytes { return -2; }
    put_i64_le(output, 0, cost);
    for i in 0..n { put_i64_le(output, 8 * (i + 1), depths[i] as i64); }
    output_bytes as i64
}
