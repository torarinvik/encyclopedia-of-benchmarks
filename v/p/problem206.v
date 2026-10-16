module problem206

const start = i64(138902663)
const minimum = i64(101010103)

fn is_square_form(value_input i64) bool {
    mut value := value_input
    mut digit := i64(9)
    for value > 0 {
        if value % 10 != digit { return false }
        value /= 100
        digit--
    }
    return true
}

@[export: 'problem206']
pub fn problem206(unused i64) i64 {
    if unused != 0 { return -1 }
    mut candidate := start
    for candidate >= minimum {
        if is_square_form(candidate * candidate) { return candidate * 10 }
        if candidate % 10 == 3 { candidate -= 6 } else { candidate -= 4 }
    }
    return -1
}
