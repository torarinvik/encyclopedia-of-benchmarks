/// Compare two indexed binary trees breadth first, including shape and values.
const MAX_NODE_COUNT: usize = 1023;

#[derive(Clone, Copy)]
struct TreeView {
    count: usize,
    root: i64,
    rows_offset: usize,
}

fn parse_tree(input: &[i64], offset: &mut usize) -> Option<TreeView> {
    if *offset > input.len() || input.len() - *offset < 2 { return None; }
    let count_value = input[*offset];
    let root = input[*offset + 1];
    if count_value < 0 || count_value > MAX_NODE_COUNT as i64 { return None; }
    let count = count_value as usize;
    let rows_offset = *offset + 2;
    if count > (input.len() - rows_offset) / 3 { return None; }
    *offset = rows_offset + 3 * count;
    Some(TreeView { count, root, rows_offset })
}

fn valid_tree(input: &[i64], tree: TreeView) -> bool {
    if tree.count == 0 { return tree.root == -1; }
    if tree.root < 0 || tree.root as u64 >= tree.count as u64 { return false; }
    let mut parents = [0usize; MAX_NODE_COUNT];
    for index in 0..tree.count {
        let row = tree.rows_offset + 3 * index;
        let value = input[row];
        let left = input[row + 1];
        let right = input[row + 2];
        if value < i32::MIN as i64 || value > i32::MAX as i64 || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= tree.count as u64) ||
            (right >= 0 && right as u64 >= tree.count as u64) { return false; }
        if left >= 0 { parents[left as usize] += 1; if parents[left as usize] > 1 { return false; } }
        if right >= 0 { parents[right as usize] += 1; if parents[right as usize] > 1 { return false; } }
    }
    for index in 0..tree.count {
        let expected = if index == tree.root as usize { 0 } else { 1 };
        if parents[index] != expected { return false; }
    }
    let mut queue = [0usize; MAX_NODE_COUNT];
    let mut seen = [false; MAX_NODE_COUNT];
    let mut head = 0;
    let mut tail = 1;
    queue[0] = tree.root as usize;
    while head < tail {
        let index = queue[head];
        head += 1;
        if seen[index] { return false; }
        seen[index] = true;
        let row = tree.rows_offset + 3 * index;
        let left = input[row + 1];
        let right = input[row + 2];
        if left >= 0 { queue[tail] = left as usize; tail += 1; }
        if right >= 0 { queue[tail] = right as usize; tail += 1; }
    }
    tail == tree.count
}

fn trees_equal(input: &[i64], first: TreeView, second: TreeView) -> i64 {
    if first.root == -1 || second.root == -1 { return if first.root == second.root { 1 } else { 0 }; }
    let mut queue1 = [0usize; MAX_NODE_COUNT];
    let mut queue2 = [0usize; MAX_NODE_COUNT];
    let mut head = 0;
    let mut tail = 1;
    queue1[0] = first.root as usize;
    queue2[0] = second.root as usize;
    while head < tail {
        let index1 = queue1[head];
        let index2 = queue2[head];
        head += 1;
        let row1 = first.rows_offset + 3 * index1;
        let row2 = second.rows_offset + 3 * index2;
        let left1 = input[row1 + 1];
        let right1 = input[row1 + 2];
        let left2 = input[row2 + 1];
        let right2 = input[row2 + 2];
        if input[row1] != input[row2] || (left1 == -1) != (left2 == -1) ||
            (right1 == -1) != (right2 == -1) { return 0; }
        if left1 >= 0 { queue1[tail] = left1 as usize; queue2[tail] = left2 as usize; tail += 1; }
        if right1 >= 0 { queue1[tail] = right1 as usize; queue2[tail] = right2 as usize; tail += 1; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn same_trees_check(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 4 + 3 * MAX_NODE_COUNT { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let mut offset = 0;
    let Some(first) = parse_tree(packed, &mut offset) else { return -1; };
    let Some(second) = parse_tree(packed, &mut offset) else { return -1; };
    if offset != length || first.count + second.count > MAX_NODE_COUNT ||
        !valid_tree(packed, first) || !valid_tree(packed, second) { return -1; }
    trees_equal(packed, first, second)
}
