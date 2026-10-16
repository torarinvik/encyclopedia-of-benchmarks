package problem206

START :: i64(138_902_663)
MINIMUM :: i64(101_010_103)

is_square_form :: proc(value_input: i64) -> bool {
    value := value_input
    digit := i64(9)
    for value > 0 {
        if value % 10 != digit do return false
        value /= 100
        digit -= 1
    }
    return true
}

@(export)
problem206 :: proc "c" (unused: i64) -> i64 {
    if unused != 0 do return -1
    candidate := START
    for candidate >= MINIMUM {
        if is_square_form(candidate * candidate) do return candidate * 10
        if candidate % 10 == 3 { candidate -= 6 } else { candidate -= 4 }
    }
    return -1
}
