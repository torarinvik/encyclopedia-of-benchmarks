/// Binary-search-tree sort with iterative insertion and in-order traversal.
const MAX_VALUES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn tree_sort(values: *mut i64, length: usize) {
    if length > MAX_VALUES { return; }
    let mut keys = [0i64; MAX_VALUES];
    let mut left = [length; MAX_VALUES];
    let mut right = [length; MAX_VALUES];
    let mut stack = [0usize; MAX_VALUES];
    let mut root = length;
    for index in 0..length {
        keys[index] = *values.add(index);
        left[index] = length;
        right[index] = length;
        if root == length { root = index; continue; }
        let mut node = root;
        loop {
            if keys[index] < keys[node] {
                if left[node] == length { left[node] = index; break; }
                node = left[node];
            } else {
                if right[node] == length { right[node] = index; break; }
                node = right[node];
            }
        }
    }
    let mut current = root;
    let mut stack_size = 0usize;
    let mut output = 0usize;
    while current != length || stack_size > 0 {
        while current != length {
            stack[stack_size] = current;
            stack_size += 1;
            current = left[current];
        }
        stack_size -= 1;
        current = stack[stack_size];
        *values.add(output) = keys[current];
        output += 1;
        current = right[current];
    }
}
