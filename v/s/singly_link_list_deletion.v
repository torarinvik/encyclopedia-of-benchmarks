module singly_link_list_deletion

const max_n = 64

@[export: 'singly_link_list_deletion']
pub fn singly_link_list_deletion(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if input == nil || length < 2 || length > max_n + 2 { return -1 }
    n_value := unsafe { input[0] }
    if n_value < 1 || n_value > max_n { return -1 }
    n := int(n_value)
    if length != usize(n + 2) { return -1 }
    position_value := unsafe { input[1] }
    if position_value < 1 || position_value > i64(n) { return -1 }
    for i in 0 .. n {
        value := unsafe { input[i + 2] }
        if value < -2147483648 || value > 2147483647 { return -1 }
    }
    bytes := 4 * (n - 1)
    if output == nil || capacity < usize(bytes) { return -2 }

    mut nodes := [max_n]i32{}
    mut next := []int{len: max_n, init: -1}
    for i in 0 .. n {
        unsafe { nodes[i] = i32(input[i + 2]) }
        if i + 1 < n { next[i] = i + 1 }
    }
    mut head := 0
    position := int(position_value)
    if position == 1 { head = next[head] }
    else {
        mut previous := head
        for i := 2; i < position; i++ { previous = next[previous] }
        removed := next[previous]
        next[previous] = next[removed]
    }
    mut node := head
    for i in 0 .. n - 1 {
        bits := u32(nodes[node])
        for byte in 0 .. 4 {
            unsafe { output[i * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
        }
        if i + 1 < n - 1 { node = next[node] }
    }
    return i64(bytes)
}
