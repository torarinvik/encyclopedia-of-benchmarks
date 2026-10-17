module slack_time_scheduling

const max_n = 64
const max_time = i64(1000000)

@[export: 'slack_time_scheduling']
pub fn slack_time_scheduling(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if input == nil || length < 1 || length > 1 + 2 * max_n { return -1 }
    n_value := unsafe { input[0] }
    if n_value < 0 || n_value > max_n { return -1 }
    n := int(n_value)
    if length != usize(1 + 2 * n) { return -1 }
    mut slack := [max_n]i64{}
    mut order := [max_n]int{}
    for i in 0 .. n {
        execution := unsafe { input[1 + 2 * i] }
        deadline := unsafe { input[2 + 2 * i] }
        if execution < 0 || execution > max_time || deadline < 0 || deadline > max_time { return -1 }
        slack[i] = deadline - execution
        order[i] = i
    }
    bytes := 8 * n
    if output == nil || capacity < usize(bytes) { return -2 }
    for i in 1 .. n {
        key := order[i]
        mut j := i
        for j > 0 && slack[key] < slack[order[j - 1]] { order[j] = order[j - 1]; j-- }
        order[j] = key
    }
    for i in 0 .. n {
        bits := u64(order[i])
        for byte in 0 .. 8 { unsafe { output[i * 8 + byte] = u8((bits >> (byte * 8)) & 255) } }
    }
    return i64(bytes)
}
