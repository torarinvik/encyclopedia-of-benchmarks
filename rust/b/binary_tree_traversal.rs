const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_NODES;

fn walk(order: i64, values: &[i64; MAX_NODES], left: &[i64; MAX_NODES], right: &[i64; MAX_NODES], node: usize, out: &mut [i64; MAX_NODES], used: &mut usize) {
    if order == 0 { out[*used] = values[node]; *used += 1; }
    if left[node] >= 0 { walk(order, values, left, right, left[node] as usize, out, used); }
    if order == 1 { out[*used] = values[node]; *used += 1; }
    if right[node] >= 0 { walk(order, values, left, right, right[node] as usize, out, used); }
    if order == 2 { out[*used] = values[node]; *used += 1; }
}

fn breadth_first(order: i64, values: &[i64; MAX_NODES], left: &[i64; MAX_NODES], right: &[i64; MAX_NODES], root: usize, out: &mut [i64; MAX_NODES], used: &mut usize) {
    let mut queue = [0usize; MAX_NODES];
    let (mut head, mut tail) = (0usize, 1usize);
    queue[0] = root;
    while head < tail {
        let node = queue[head];
        head += 1;
        out[*used] = values[node];
        *used += 1;
        let (first, second) = if order == 3 { (left[node], right[node]) } else { (right[node], left[node]) };
        if first >= 0 { queue[tail] = first as usize; tail += 1; }
        if second >= 0 { queue[tail] = second as usize; tail += 1; }
    }
}

fn breadth_first_zigzag(values: &[i64; MAX_NODES], left: &[i64; MAX_NODES], right: &[i64; MAX_NODES], root: usize, out: &mut [i64; MAX_NODES], used: &mut usize) {
    let mut queue = [0usize; MAX_NODES];
    let (mut head, mut tail, mut level) = (0usize, 1usize, 0usize);
    queue[0] = root;
    while head < tail {
        let level_end = tail;
        let start = *used;
        while head < level_end {
            let node = queue[head]; head += 1;
            out[*used] = values[node]; *used += 1;
            if left[node] >= 0 { queue[tail] = left[node] as usize; tail += 1; }
            if right[node] >= 0 { queue[tail] = right[node] as usize; tail += 1; }
        }
        if level % 2 == 1 {
            let mut lo = start;
            let mut hi = *used;
            while lo < hi {
                hi -= 1;
                if lo >= hi { break; }
                out.swap(lo, hi);
                lo += 1;
            }
        }
        level += 1;
    }
}

fn mark_reachable(left: &[i64; MAX_NODES], right: &[i64; MAX_NODES], root: usize, seen: &mut [bool; MAX_NODES]) -> usize {
    let mut stack = [0usize; MAX_NODES];
    let mut top = 1usize;
    let mut count = 0usize;
    stack[0] = root;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if seen[node] { continue; }
        seen[node] = true;
        count += 1;
        if right[node] >= 0 { stack[top] = right[node] as usize; top += 1; }
        if left[node] >= 0 { stack[top] = left[node] as usize; top += 1; }
    }
    count
}

unsafe fn put_i64(output: *mut u8, index: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(index * 8 + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_traversal(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let order = *input;
    let count_value = *input.add(1);
    let root_value = *input.add(2);
    if !(0..=6).contains(&order) || count_value < 0 || count_value > MAX_NODES as i64 || length != 3 + 3 * count_value as usize { return -1; }
    let n = count_value as usize;
    if (n == 0 && root_value != -1) || (n > 0 && (root_value < 0 || root_value >= n as i64)) { return -1; }
    let mut values = [0i64; MAX_NODES];
    let mut left = [-1i64; MAX_NODES];
    let mut right = [-1i64; MAX_NODES];
    let mut parents = [0u8; MAX_NODES];
    for i in 0..n {
        values[i] = *input.add(3 + 3 * i);
        left[i] = *input.add(4 + 3 * i);
        right[i] = *input.add(5 + 3 * i);
        if left[i] < -1 || left[i] >= n as i64 || right[i] < -1 || right[i] >= n as i64 || left[i] == i as i64 || right[i] == i as i64 { return -1; }
        if left[i] >= 0 { parents[left[i] as usize] += 1; if parents[left[i] as usize] > 1 { return -1; } }
        if right[i] >= 0 { parents[right[i] as usize] += 1; if parents[right[i] as usize] > 1 { return -1; } }
    }
    let mut result = [0i64; MAX_NODES];
    let mut used = 0usize;
    if n > 0 {
        let root = root_value as usize;
        for i in 0..n { if parents[i] != (if i == root { 0 } else { 1 }) { return -1; } }
        let mut seen = [false; MAX_NODES];
        if mark_reachable(&left, &right, root, &mut seen) != n { return -1; }
        if order <= 2 { walk(order, &values, &left, &right, root, &mut result, &mut used); }
        else if order == 5 { walk(1, &values, &right, &left, root, &mut result, &mut used); }
        else if order == 6 { breadth_first_zigzag(&values, &left, &right, root, &mut result, &mut used); }
        else { breadth_first(order, &values, &left, &right, root, &mut result, &mut used); }
    }
    if output.is_null() || capacity < used * 8 { return -2; }
    for i in 0..used { put_i64(output, i, result[i]); }
    (used * 8) as i64
}
