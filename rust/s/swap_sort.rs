/// Count minimum swaps needed to order a distinct-value array.
const MAX_VALUES: usize = 256;

fn position_less(keys: &[i64; MAX_VALUES], order: &[usize; MAX_VALUES], left: usize, right: usize) -> bool {
    let a = order[left];
    let b = order[right];
    keys[a] < keys[b] || (keys[a] == keys[b] && a < b)
}

fn sift_down(keys: &[i64; MAX_VALUES], order: &mut [usize; MAX_VALUES], heap_length: usize, start_root: usize) {
    let mut root = start_root;
    while root < heap_length / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < heap_length && position_less(keys, order, child, child + 1) { child += 1; }
        if !position_less(keys, order, root, child) { break; }
        order.swap(root, child);
        root = child;
    }
}

#[no_mangle]
pub unsafe extern "C" fn swap_sort(values: *const i64, length: usize) -> i64 {
    if length > MAX_VALUES { return -1; }
    let mut keys = [0i64; MAX_VALUES];
    let mut order = [0usize; MAX_VALUES];
    let mut visited = [false; MAX_VALUES];
    for index in 0..length {
        keys[index] = *values.add(index);
        order[index] = index;
    }
    let mut start = length / 2;
    while start > 0 { start -= 1; sift_down(&keys, &mut order, length, start); }
    let mut finish = length;
    while finish > 1 {
        finish -= 1;
        order.swap(0, finish);
        sift_down(&keys, &mut order, finish, 0);
    }
    for index in 1..length {
        if keys[order[index - 1]] == keys[order[index]] { return -1; }
    }
    let mut swaps = 0usize;
    for first in 0..length {
        if visited[first] { continue; }
        let mut node = first;
        let mut cycle_length = 0usize;
        while !visited[node] {
            visited[node] = true;
            node = order[node];
            cycle_length += 1;
        }
        if cycle_length > 0 { swaps += cycle_length - 1; }
    }
    swaps as i64
}
