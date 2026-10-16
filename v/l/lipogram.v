module lipogram

@[export: 'lipogram']
pub fn lipogram(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 1026 { return -1 }
    n_value := unsafe { input[0] }
    if n_value < 0 || n_value > 1024 || length != usize(n_value + 2) { return -1 }
    n := int(n_value)
    expected := unsafe { input[length - 1] }
    if expected < 0 || expected > 67108863 { return -1 }
    mut seen := [26]bool{}
    for i in 0 .. n {
        mut ch := unsafe { input[i + 1] }
        if ch >= 65 && ch <= 90 { ch += 32 }
        if ch >= 97 && ch <= 122 {
            seen[int(ch - 97)] = true
        } else if ch != 9 && ch != 10 && ch != 11 && ch != 12 && ch != 13 && ch != 32 {
            return -1
        }
    }
    mut missing := i64(0)
    mut bit := i64(1)
    for i in 0 .. 26 {
        if !seen[i] { missing += bit }
        bit *= 2
    }
    return if missing == expected { 1 } else { 0 }
}
