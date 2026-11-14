// Uncompiled and unexecuted next-occurrence automaton draft.
module subsequence_automaton

@[export: 'subsequence_automaton']
pub fn subsequence_automaton(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 354 { return -1 }
        if input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32 { return -1 }
        n := int(input[0])
        queries := int(input[1])
        if int(length) < 2+n { return -1 }
        for i in 0 .. n { if input[2+i] < 0 || input[2+i] > 3 { return -1 } }
        mut next := [260]int{}
        for c in 0 .. 4 { next[4*n+c] = n }
        mut row := n
        for row > 0 {
            row--
            for c in 0 .. 4 { next[4*row+c] = next[4*(row+1)+c] }
            next[4*row+int(input[2+row])] = row
        }
        mut pos := 2+n
        mut total := 0
        mut answer := i64(0)
        for q in 0 .. queries {
            if pos == int(length) || input[pos] < 0 || input[pos] > 256 { return -1 }
            count := int(input[pos]); pos++
            if count > 256-total || count > int(length)-pos { return -1 }
            mut cursor := 0
            mut matches := true
            for i in 0 .. count {
                symbol := input[pos+i]
                if symbol < 0 || symbol > 3 { return -1 }
                if matches {
                    found := next[4*cursor+int(symbol)]
                    if found == n { matches = false } else { cursor = found+1 }
                }
            }
            if matches { answer += i64(q+1) }
            pos += count
            total += count
        }
        return if pos == int(length) { answer } else { -1 }
    }
}
