module backward_nondeterministic_dawg_match

@[export: 'backward_nondeterministic_dawg_match']
pub fn backward_nondeterministic_dawg_match(values &i64, length usize) i64 {
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
    mut masks := [26]u64{}
    for i in 0 .. m {
        letter := int(unsafe { values[2 + n + i] } - 97)
        masks[letter] |= u64(1) << (m - 1 - i)
    }
    mut start := 0
    for start <= n - m {
        mut remaining := m
        mut shift := m
        mut states := ~u64(0)
        for remaining > 0 && states != 0 {
            remaining--
            letter := int(unsafe { values[2 + start + remaining] } - 97)
            states &= masks[letter]
            if states != 0 {
                if remaining == 0 { return i64(start) }
                shift = remaining
            }
            states <<= 1
        }
        start += shift
    }
    return -1
}
