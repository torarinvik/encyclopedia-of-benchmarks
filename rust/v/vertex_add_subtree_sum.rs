use std::slice;

const MAX_N: usize = 128;
const MAX_Q: usize = 256;
const MAX_INPUT_VALUES: usize = 2 * MAX_N + 1 + 3 * MAX_Q;
const MAX_VALUE: i64 = 1_000_000;

fn fenwick_add(tree: &mut [i64; MAX_N + 1], n: usize, position: usize, delta: i64) {
    let mut index = position + 1;
    while index <= n {
        tree[index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn fenwick_prefix(tree: &[i64; MAX_N + 1], count: usize) -> i64 {
    let mut total = 0;
    let mut index = count;
    while index > 0 {
        total += tree[index];
        index -= index & index.wrapping_neg();
    }
    total
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn vertex_add_subtree_sum(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 * n + 1 + 3 * q { return -1; }

    let mut values = [0i64; MAX_N];
    let mut first_child = [-1i64; MAX_N];
    let mut next_sibling = [-1i64; MAX_N];
    for vertex in 0..n {
        values[vertex] = input[2 + vertex];
        if !(0..=MAX_VALUE).contains(&values[vertex]) { return -1; }
    }
    let parent_start = 2 + n;
    for vertex in 1..n {
        let parent_value = input[parent_start + vertex - 1];
        if parent_value < 0 || parent_value as usize >= vertex { return -1; }
        let parent = parent_value as usize;
        next_sibling[vertex] = first_child[parent];
        first_child[parent] = vertex as i64;
    }

    let mut tin = [0usize; MAX_N];
    let mut tout = [0usize; MAX_N];
    let mut stack_node = [0usize; MAX_N];
    let mut stack_next_child = [0i64; MAX_N];
    let (mut timer, mut top) = (0usize, 1usize);
    stack_node[0] = 0;
    stack_next_child[0] = first_child[0];
    tin[0] = timer;
    timer += 1;
    while top > 0 {
        let frame = top - 1;
        let child_value = stack_next_child[frame];
        if child_value < 0 {
            tout[stack_node[frame]] = timer;
            top -= 1;
            continue;
        }
        let child = child_value as usize;
        stack_next_child[frame] = next_sibling[child];
        tin[child] = timer;
        timer += 1;
        stack_node[top] = child;
        stack_next_child[top] = first_child[child];
        top += 1;
    }

    let mut fenwick = [0i64; MAX_N + 1];
    for vertex in 0..n { fenwick_add(&mut fenwick, n, tin[vertex], values[vertex]); }
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    let operation_start = parent_start + n - 1;
    for index in 0..q {
        let offset = operation_start + 3 * index;
        let (kind, vertex_value, operand) = (input[offset], input[offset + 1], input[offset + 2]);
        if kind == 0 {
            if vertex_value < 0 || vertex_value as usize >= n || !(0..=MAX_VALUE).contains(&operand) { return -1; }
            let vertex = vertex_value as usize;
            values[vertex] += operand;
            fenwick_add(&mut fenwick, n, tin[vertex], operand);
        } else if kind == 1 {
            if vertex_value < 0 || vertex_value as usize >= n || operand != 0 { return -1; }
            let vertex = vertex_value as usize;
            answers[answer_count] = fenwick_prefix(&fenwick, tout[vertex]) - fenwick_prefix(&fenwick, tin[vertex]);
            answer_count += 1;
        } else { return -1; }
    }

    let output_bytes = 8 * answer_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }
    if output_bytes > 0 {
        let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
        for index in 0..answer_count { put_i64_le(output, 8 * index, answers[index]); }
    }
    output_bytes as i64
}
