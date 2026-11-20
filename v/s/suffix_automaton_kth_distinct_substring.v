// Independently authored draft; not compiled or run.
@[export: 'suffix_automaton_kth_distinct_substring']
pub fn suffix_automaton_kth_distinct_substring(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if length < 3 || length > 259 { return -1 }
    unsafe {
        if input == nil { return -1 }
        raw_n := input[0]
        mut k := input[1]
        if raw_n < 1 || raw_n > 256 || length != usize(raw_n+2) || k < 1 { return -1 }
        n := int(raw_n)
        for i in 0 .. n { if input[i+2] < 0 || input[i+2] > 255 { return -1 } }
        mut next := [131072]int{}
        mut links := [512]int{}
        mut lengths := [512]int{}
        mut paths := [512]i64{}
        for i in 0 .. 131072 { next[i] = -1 }
        for i in 0 .. 512 { links[i] = -1 }
        mut count := 1
        mut last := 0
        for i in 0 .. n {
            symbol := int(input[i+2])
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
        mut buckets := [257]int{}
        mut order := [512]int{}
        for i in 0 .. count { buckets[lengths[i]]++ }
        for i in 1 .. n+1 { buckets[i] += buckets[i-1] }
        mut i := count
        for i > 0 {
            i--
            l := lengths[i]
            buckets[l]--
            order[buckets[l]] = i
        }
        i = count
        for i > 0 {
            i--
            state := order[i]
            for c in 0 .. 256 {
                target := next[state*256+c]
                if target >= 0 { paths[state] += 1 + paths[target] }
            }
        }
        if k > paths[0] { return -1 }
        mut result := [256]u8{}
        mut used := 0
        mut state := 0
        for {
            mut found := false
            for c in 0 .. 256 {
                target := next[state*256+c]
                if target < 0 { continue }
                group := 1 + paths[target]
                if k > group { k -= group; continue }
                result[used] = u8(c)
                used++
                state = target
                found = true
                break
            }
            if !found { return -1 }
            if k == 1 { break }
            k--
        }
        if output == nil || capacity < usize(used) { return -2 }
        for j in 0 .. used { output[j] = result[j] }
        return i64(used)
    }
}
