// Uncompiled suffix-automaton minimum-rotation draft.
@[export: 'suffix_automaton_minimum_rotation']
pub fn suffix_automaton_minimum_rotation(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if length < 2 || length > 258 { return -1 }
    unsafe {
        if input == nil { return -1 }
        raw_n := input[0]
        if raw_n < 1 || raw_n > 256 || length != usize(raw_n+1) { return -1 }
        n := int(raw_n)
        for i in 1 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
        if output == nil || capacity < usize(n) { return -2 }
        mut next := [262144]int{}
        mut links := [1024]int{}
        mut lengths := [1024]int{}
        for i in 0 .. 262144 { next[i] = -1 }
        for i in 0 .. 1024 { links[i] = -1 }
        mut count := 1
        mut last := 0
        for i in 0 .. 2*n {
            symbol := int(input[1+i%n])
            current := count
            count++
            lengths[current] = lengths[last]+1
            mut p := last
            for p >= 0 && next[p*256+symbol] < 0 {
                next[p*256+symbol] = current
                p = links[p]
            }
            if p < 0 { links[current] = 0 } else {
                q := next[p*256+symbol]
                if lengths[p]+1 == lengths[q] { links[current] = q } else {
                    clone := count
                    count++
                    for c in 0 .. 256 { next[clone*256+c] = next[q*256+c] }
                    links[clone] = links[q]; lengths[clone] = lengths[p]+1
                    for p >= 0 && next[p*256+symbol] == q {
                        next[p*256+symbol] = clone
                        p = links[p]
                    }
                    links[q] = clone; links[current] = clone
                }
            }
            last = current
        }
        mut state := 0
        for i in 0 .. n {
            mut symbol := 0
            for next[state*256+symbol] < 0 { symbol++ }
            output[i] = u8(symbol)
            state = next[state*256+symbol]
        }
        return raw_n
    }
}
