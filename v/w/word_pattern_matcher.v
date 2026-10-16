module word_pattern_matcher

fn match_at(pattern &i64, text &i64, plen int, tlen int, pi int, ti int, mut starts [95]int, mut sizes [95]int) bool {
    if pi == plen { return ti == tlen }
    symbol := int(unsafe { pattern[pi] - 32 })
    if sizes[symbol] >= 0 {
        size := sizes[symbol]
        if ti + size > tlen { return false }
        for j in 0 .. size { if unsafe { text[ti+j] != text[starts[symbol]+j] } { return false } }
        return match_at(pattern, text, plen, tlen, pi + 1, ti + size, mut starts, mut sizes)
    }
    for size in 1 .. (tlen - ti + 1) {
        mut used := false
        for other in 0 .. 95 {
            if sizes[other] == size {
                mut same := true
                for j in 0 .. size { if unsafe { text[ti+j] != text[starts[other]+j] } { same = false; break } }
                if same { used = true; break }
            }
        }
        if used { continue }
        starts[symbol] = ti; sizes[symbol] = size
        if match_at(pattern, text, plen, tlen, pi + 1, ti + size, mut starts, mut sizes) { return true }
        sizes[symbol] = -1
    }
    return false
}

@[export: 'word_pattern_matcher']
fn word_pattern_matcher(input &i64, length usize, output &u8, capacity usize) i64 {
    _ = output; _ = capacity
    if unsafe { input == nil } || length < 2 { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 8 { return -1 }
        plen := int(input[0]); if length < usize(plen+2) { return -1 }
        text_index := plen+1
        if input[text_index] < 0 || input[text_index] > 32 { return -1 }
        tlen := int(input[text_index]); if length != usize(text_index+1+tlen) { return -1 }
        for i in 0 .. plen { if input[i+1] < 32 || input[i+1] > 126 { return -1 } }
        for i in 0 .. tlen { if input[text_index+1+i] < 32 || input[text_index+1+i] > 126 { return -1 } }
        mut starts := [95]int{init: -1}; mut sizes := [95]int{init: -1}
        if match_at(input+1, input+text_index+1, plen, tlen, 0, 0, mut starts, mut sizes) { return 1 }
        return 0
    }
}
