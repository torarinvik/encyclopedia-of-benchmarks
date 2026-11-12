use std::slice;

const MAX_N: usize = 32;
const MAX_K: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_VIRTUAL: usize = 32;
const MAX_CANDIDATES: usize = 64;
const MAX_WORDS: usize = 1 + 3 * MAX_VIRTUAL;

fn lca(mut a: usize, mut b: usize, parent: &[usize; MAX_N], depth: &[usize; MAX_N]) -> usize {
    while depth[a] > depth[b] { a = parent[a]; }
    while depth[b] > depth[a] { b = parent[b]; }
    while a != b { a = parent[a]; b = parent[b]; }
    a
}

fn is_ancestor(a: usize, b: usize, tin: &[usize; MAX_N], tout: &[usize; MAX_N]) -> bool {
    tin[a] <= tin[b] && tin[b] < tout[a]
}

fn sort_by_tin(items: &mut [usize; MAX_CANDIDATES], count: usize, tin: &[usize; MAX_N]) {
    for i in 1..count {
        let value = items[i];
        let mut j = i;
        while j > 0 && tin[items[j - 1]] > tin[value] {
            items[j] = items[j - 1];
            j -= 1;
        }
        items[j] = value;
    }
}

fn put_word(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn virtual_tree(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, k_value) = (input[0], input[1]);
    if n_value < 1 || n_value > MAX_N as i64 || k_value < 0 ||
        k_value > MAX_K as i64 || k_value > n_value { return -1; }
    let (n, k) = (n_value as usize, k_value as usize);
    if length != n + k + 1 { return -1; }

    let mut parent = [0usize; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut children = [[0usize; MAX_N]; MAX_N];
    let mut child_count = [0usize; MAX_N];
    for vertex in 1..n {
        let p_value = input[vertex + 1];
        if p_value < 0 || p_value as usize >= n || p_value as usize == vertex { return -1; }
        let p = p_value as usize;
        parent[vertex] = p;
        children[p][child_count[p]] = vertex;
        child_count[p] += 1;
    }
    let mut marks = [0usize; MAX_K];
    for index in 0..k {
        let mark_value = input[n + 1 + index];
        if mark_value < 0 || mark_value as usize >= n { return -1; }
        marks[index] = mark_value as usize;
        for previous in 0..index {
            if marks[previous] == marks[index] { return -1; }
        }
    }

    let mut tin = [usize::MAX; MAX_N];
    let mut tout = [usize::MAX; MAX_N];
    let mut node_stack = [0usize; MAX_N];
    let mut next_stack = [0usize; MAX_N];
    let (mut timer, mut top, mut reached) = (0usize, 1usize, 1usize);
    node_stack[0] = 0;
    tin[0] = timer;
    timer += 1;
    while top > 0 {
        let frame = top - 1;
        let current = node_stack[frame];
        if next_stack[frame] == child_count[current] {
            tout[current] = timer;
            top -= 1;
            continue;
        }
        let child = children[current][next_stack[frame]];
        next_stack[frame] += 1;
        if tin[child] != usize::MAX { return -1; }
        tin[child] = timer;
        timer += 1;
        depth[child] = depth[current] + 1;
        reached += 1;
        node_stack[top] = child;
        next_stack[top] = 0;
        top += 1;
    }
    if reached != n { return -1; }

    let mut words = [0i64; MAX_WORDS];
    let mut word_count = 1usize;
    if k == 0 {
        words[0] = 0;
    } else {
        for i in 1..k {
            let value = marks[i];
            let mut j = i;
            while j > 0 && tin[marks[j - 1]] > tin[value] {
                marks[j] = marks[j - 1];
                j -= 1;
            }
            marks[j] = value;
        }
        let mut nodes = [0usize; MAX_CANDIDATES];
        let mut count = 0usize;
        nodes[count] = 0;
        count += 1;
        for index in 0..k { nodes[count] = marks[index]; count += 1; }
        for index in 1..k {
            nodes[count] = lca(marks[index - 1], marks[index], &parent, &depth);
            count += 1;
        }
        sort_by_tin(&mut nodes, count, &tin);
        let mut unique = [0usize; MAX_VIRTUAL];
        let mut unique_count = 0usize;
        for index in 0..count {
            if unique_count == 0 || unique[unique_count - 1] != nodes[index] {
                unique[unique_count] = nodes[index];
                unique_count += 1;
            }
        }
        words[0] = unique_count as i64;
        let mut stack = [0usize; MAX_VIRTUAL];
        let mut stack_size = 0usize;
        for index in 0..unique_count {
            let vertex = unique[index];
            while stack_size > 0 && !is_ancestor(stack[stack_size - 1], vertex, &tin, &tout) {
                stack_size -= 1;
            }
            let virtual_parent = if stack_size == 0 { vertex } else { stack[stack_size - 1] };
            words[word_count] = vertex as i64;
            words[word_count + 1] = virtual_parent as i64;
            words[word_count + 2] = (depth[vertex] - depth[virtual_parent]) as i64;
            word_count += 3;
            stack[stack_size] = vertex;
            stack_size += 1;
        }
    }

    let output_bytes = word_count * 8;
    if output_ptr.is_null() || capacity < output_bytes { return -2; }
    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for index in 0..word_count { put_word(output, index * 8, words[index]); }
    output_bytes as i64
}
