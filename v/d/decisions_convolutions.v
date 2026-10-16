module decisions_convolutions

const max_decisions = 64
const max_criteria = 16
const max_value = i64(100000)

@[export: 'decisions_convolutions']
pub fn decisions_convolutions(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 3 { return -1 }
    method := unsafe { input[0] }
    n_arg := unsafe { input[1] }
    m_arg := unsafe { input[2] }
    if (method != 0 && method != 1) || n_arg < 1 || n_arg > max_decisions || m_arg < 1 || m_arg > max_criteria { return -1 }
    n := int(n_arg)
    m := int(m_arg)
    if length != usize(3 + m + n * m) { return -1 }
    for j in 0 .. m {
        value := unsafe { input[3 + j] }
        if value < -max_value || value > max_value { return -1 }
    }
    for i in 0 .. n * m {
        value := unsafe { input[3 + m + i] }
        if value < -max_value || value > max_value { return -1 }
    }
    mut best_score := i64(0)
    mut best_index := 0
    for i in 0 .. n {
        mut score := i64(0)
        for j in 0 .. m {
            product := unsafe { input[3 + m + i * m + j] * input[3 + j] }
            if method == 0 { score += product }
            else if j == 0 || product < score { score = product }
        }
        if i == 0 || score > best_score { best_score = score; best_index = i }
    }
    return i64(best_index)
}
