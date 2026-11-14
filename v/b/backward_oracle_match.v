module backward_oracle_match

@[export: 'backward_oracle_match']
pub fn backward_oracle_match(values &i64, length usize) i64 {
    if unsafe { values == nil } || length < 2 || length > 4161 { return -2 }
    nv := unsafe { values[0] }
    mv := unsafe { values[1] }
    if nv < 0 || nv > 4096 || mv < 0 || mv > 63 { return -2 }
    n := int(nv)
    m := int(mv)
    if length != usize(2 + n + m) { return -2 }
    for i in 2 .. int(length) {
        x := unsafe { values[i] }
        if x < 97 || x > 122 { return -2 }
    }
    if m == 0 { return 0 }
    if m > n { return -1 }
    mut next := [1664]int{}
    mut suffix := [64]int{}
    for i in 0 .. 1664 { next[i] = -1 }
    for i in 0 .. 64 { suffix[i] = -1 }
    for i in 0 .. m {
        letter := int(unsafe { values[2 + n + m - 1 - i] } - 97)
        next[i * 26 + letter] = i + 1
        mut k := suffix[i]
        for k >= 0 && next[k * 26 + letter] < 0 {
            next[k * 26 + letter] = i + 1
            k = suffix[k]
        }
        suffix[i + 1] = if k < 0 { 0 } else { next[k * 26 + letter] }
    }
    mut start := 0
    for start <= n - m {
        mut state := 0
        mut remaining := m
        mut shift := m
        for remaining > 0 {
            remaining--
            letter := int(unsafe { values[2 + start + remaining] } - 97)
            state = next[state * 26 + letter]
            if state < 0 { shift = remaining + 1; break }
            if remaining == 0 { return i64(start) }
        }
        start += shift
    }
    return -1
}
