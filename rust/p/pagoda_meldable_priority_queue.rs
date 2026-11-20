//! Pagoda priority queue with parent/extreme-leaf links.
use std::slice;

const MAX_QUEUES: usize = 8;
const MAX_OPERATIONS: usize = 64;
const MAX_PARSEABLE_WORDS: usize = 259;
const NIL: i64 = -1;

fn branch_stack(
    root: i64,
    right_branch: bool,
    node_count: usize,
    leftmost: &[i64; MAX_OPERATIONS],
    rightmost: &[i64; MAX_OPERATIONS],
    stack: &mut [i64; MAX_OPERATIONS],
) -> isize {
    let mut node = if right_branch { rightmost[root as usize] } else { leftmost[root as usize] };
    if node < 0 || node as usize >= node_count { return -1; }
    let mut count = 0usize;
    while count < node_count {
        stack[count] = node;
        count += 1;
        if node == root { return count as isize; }
        node = if right_branch { rightmost[node as usize] } else { leftmost[node as usize] };
        if node < 0 || node as usize >= node_count { return -1; }
    }
    -1
}

fn pagoda_meld(
    g_root: i64,
    d_root: i64,
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    leftmost: &mut [i64; MAX_OPERATIONS],
    rightmost: &mut [i64; MAX_OPERATIONS],
) -> i64 {
    if g_root < 0 { return d_root; }
    if d_root < 0 { return g_root; }

    let mut g_branch = [NIL; MAX_OPERATIONS];
    let mut d_branch = [NIL; MAX_OPERATIONS];
    let g_count = branch_stack(g_root, true, node_count, leftmost, rightmost, &mut g_branch);
    let d_count = branch_stack(d_root, false, node_count, leftmost, rightmost, &mut d_branch);
    if g_count < 1 || d_count < 1 { return -2; }
    let (g_count, d_count) = (g_count as usize, d_count as usize);

    let (mut gi, mut di) = (0usize, 0usize);
    let (mut central, mut central_left, mut central_right) = (NIL, NIL, NIL);
    while gi < g_count || di < d_count {
        let take_g = di >= d_count ||
            (gi < g_count && keys[g_branch[gi] as usize] > keys[d_branch[di] as usize]);
        let (node, kept_extreme) = if take_g {
            let node = g_branch[gi];
            gi += 1;
            (node, leftmost[node as usize])
        } else {
            let node = d_branch[di];
            di += 1;
            (node, rightmost[node as usize])
        };

        if central >= 0 {
            let index = central as usize;
            if take_g {
                rightmost[index] = node;
                leftmost[index] = if central_left == central { NIL } else { central_left };
            } else {
                leftmost[index] = node;
                rightmost[index] = if central_right == central { NIL } else { central_right };
            }
        }

        let new_left = if take_g {
            if kept_extreme < 0 { node } else { kept_extreme }
        } else if central >= 0 { central_left } else { node };
        let new_right = if take_g {
            if central >= 0 { central_right } else { node }
        } else if kept_extreme < 0 { node } else { kept_extreme };
        leftmost[node as usize] = new_left;
        rightmost[node as usize] = new_right;
        central = node;
        central_left = new_left;
        central_right = new_right;
    }
    central
}

fn pagoda_extract_min(
    root: i64,
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    leftmost: &mut [i64; MAX_OPERATIONS],
    rightmost: &mut [i64; MAX_OPERATIONS],
) -> i64 {
    let old_leftmost = leftmost[root as usize];
    let old_rightmost = rightmost[root as usize];
    let (mut left_child, mut right_child) = (NIL, NIL);
    if old_leftmost != root {
        let mut node = old_leftmost;
        let mut steps = 0usize;
        while node >= 0 && (node as usize) < node_count &&
              leftmost[node as usize] != root && steps < node_count {
            node = leftmost[node as usize];
            steps += 1;
        }
        if node < 0 || node as usize >= node_count || leftmost[node as usize] != root { return -2; }
        left_child = node;
    }
    if old_rightmost != root {
        let mut node = old_rightmost;
        let mut steps = 0usize;
        while node >= 0 && (node as usize) < node_count &&
              rightmost[node as usize] != root && steps < node_count {
            node = rightmost[node as usize];
            steps += 1;
        }
        if node < 0 || node as usize >= node_count || rightmost[node as usize] != root { return -2; }
        right_child = node;
    }

    if left_child >= 0 {
        leftmost[left_child as usize] = old_leftmost;
        if rightmost[left_child as usize] < 0 { rightmost[left_child as usize] = left_child; }
    }
    if right_child >= 0 {
        rightmost[right_child as usize] = old_rightmost;
        if leftmost[right_child as usize] < 0 { leftmost[right_child as usize] = right_child; }
    }
    let new_root = pagoda_meld(right_child, left_child, node_count, &keys, leftmost, rightmost);
    leftmost[root as usize] = NIL;
    rightmost[root as usize] = NIL;
    new_root
}

#[no_mangle]
pub unsafe extern "C" fn pagoda_meldable_priority_queue(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_WORDS { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    let raw_queues = values[0];
    let raw_operations = values[1];
    if !(1..=MAX_QUEUES as i64).contains(&raw_queues) ||
       !(0..=MAX_OPERATIONS as i64).contains(&raw_operations) ||
       length != 2 + 4 * raw_operations as usize || length > 258 { return -1; }

    let mut keys = [0i64; MAX_OPERATIONS];
    let mut leftmost = [NIL; MAX_OPERATIONS];
    let mut rightmost = [NIL; MAX_OPERATIONS];
    let mut roots = [NIL; MAX_QUEUES];
    let mut node_count = 0usize;
    let mut result = 0i64;
    for op in 0..raw_operations as usize {
        let offset = 2 + 4 * op;
        let opcode = values[offset];
        let first = values[offset + 1];
        let second = values[offset + 2];
        let priority = values[offset + 3];
        if opcode == 1 {
            if first < 0 || first >= raw_queues || second != 0 ||
               !(-1000..=1000).contains(&priority) || node_count >= MAX_OPERATIONS ||
               keys[..node_count].contains(&priority) { return -1; }
            let node = node_count as i64;
            node_count += 1;
            keys[node as usize] = priority;
            leftmost[node as usize] = node;
            rightmost[node as usize] = node;
            let merged = pagoda_meld(roots[first as usize], node, node_count, &keys, &mut leftmost, &mut rightmost);
            if merged < 0 { return -1; }
            roots[first as usize] = merged;
        } else if opcode == 2 {
            if first < 0 || first >= raw_queues || second < 0 || second >= raw_queues ||
               first == second || priority != 0 { return -1; }
            let merged = pagoda_meld(roots[first as usize], roots[second as usize], node_count,
                                     &keys, &mut leftmost, &mut rightmost);
            if merged == -2 { return -1; }
            roots[first as usize] = merged;
            roots[second as usize] = NIL;
        } else if opcode == 3 || opcode == 4 {
            if first < 0 || first >= raw_queues || second != 0 || priority != 0 || roots[first as usize] < 0 {
                return -1;
            }
            let root = roots[first as usize];
            result += (op as i64 + 1) * (keys[root as usize] + 1001);
            if opcode == 4 {
                let new_root = pagoda_extract_min(root, node_count, &keys, &mut leftmost, &mut rightmost);
                if new_root == -2 { return -1; }
                roots[first as usize] = new_root;
            }
        } else { return -1; }
    }
    result
}
