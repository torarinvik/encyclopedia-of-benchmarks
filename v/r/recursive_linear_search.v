module recursive_linear_search

const max_n = 64

fn search_recursive(items []i32, left int, right int, target i32) int {
    if left > right { return -1 }
    if items[left] == target { return left }
    if items[right] == target { return right }
    return search_recursive(items, left + 1, right - 1, target)
}

@[export: 'recursive_linear_search']
pub fn recursive_linear_search(input &i64, length usize) i64 {
    if input == nil || length < 4 || length > max_n + 2 { return -1 }
    n_value := unsafe { input[0] }
    target_value := unsafe { input[1] }
    if n_value < 2 || n_value > max_n || length != usize(n_value + 2) { return -1 }
    if target_value < -2147483648 || target_value > 2147483647 { return -1 }
    n := int(n_value)
    mut items := []i32{len: n}
    for i in 0 .. n {
        value := unsafe { input[i + 2] }
        if value < -2147483648 || value > 2147483647 { return -1 }
        items[i] = i32(value)
        for j in 0 .. i { if items[j] == items[i] { return -1 } }
    }
    return i64(search_recursive(items, 0, n - 1, i32(target_value)))
}
