module path_sum

fn path_has_sum(input &i64, node usize, sum i64, target i64) bool {
    base := usize(2) + usize(3) * node
    next_sum := sum + unsafe { input[base] }
    left := unsafe { input[base + 1] }
    right := unsafe { input[base + 2] }
    if left == -1 && right == -1 { return next_sum == target }
    return (left != -1 && path_has_sum(input, usize(left), next_sum, target)) ||
        (right != -1 && path_has_sum(input, usize(right), next_sum, target))
}

@[export: 'path_sum']
pub fn path_sum(input &i64, length usize) i64 {
    if length < 2 { return -1 }
    target := unsafe { input[0] }
    count_value := unsafe { input[1] }
    if count_value < 0 || count_value > 63 { return -1 }
    count := int(count_value)
    if length != usize(2 + 3 * count) { return -1 }
    if count == 0 { return 0 }
    for index in 0 .. count {
        base := 2 + 3 * index
        value := unsafe { input[base] }
        left := unsafe { input[base + 1] }
        right := unsafe { input[base + 2] }
        if value < -2147483648 || value > 2147483647 || left < -1 || left >= count_value || right < -1 || right >= count_value { return -1 }
    }
    mut seen := [63]bool{init: false}
    mut stack := [63]usize{init: 0}
    mut top := usize(1)
    mut visited := 0
    stack[0] = 0
    for top > 0 {
        top--
        node := stack[top]
        if seen[node] { return -1 }
        seen[node] = true
        visited++
        base := usize(2) + usize(3) * node
        left := unsafe { input[base + 1] }
        right := unsafe { input[base + 2] }
        if left != -1 { stack[top] = usize(left); top++ }
        if right != -1 { stack[top] = usize(right); top++ }
    }
    if visited != count { return -1 }
    return if path_has_sum(input, 0, 0, target) { 1 } else { 0 }
}
