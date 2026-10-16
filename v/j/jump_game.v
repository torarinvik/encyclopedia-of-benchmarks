module jump_game

@[export: 'jump_game']
pub fn jump_game(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 1025 { return -2 }
    n_value := unsafe { input[0] }
    if n_value < 1 || n_value > 1024 || length != usize(n_value + 1) { return -2 }
    n := int(n_value)
    for i in 0 .. n {
        jump := unsafe { input[i + 1] }
        if jump < 0 || jump > 1000000 { return -2 }
    }
    mut last_pos := n - 1
    for i := n - 1; i >= 0; i-- {
        if i + int(unsafe { input[i + 1] }) >= last_pos { last_pos = i }
    }
    return if last_pos == 0 { 1 } else { 0 }
}
