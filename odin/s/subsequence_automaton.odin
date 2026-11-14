// Uncompiled and unexecuted next-occurrence automaton draft.
package subsequence_automaton
import "core:c"

@(export)
subsequence_automaton :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 354 { return -1 }
    if input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32 { return -1 }
    n, queries := int(input[0]), int(input[1])
    if int(length) < 2+n { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 3 { return -1 } }
    next: [65][4]int
    for c := 0; c < 4; c += 1 { next[n][c] = n }
    for row := n-1; row >= 0; row -= 1 {
        next[row] = next[row+1]
        next[row][int(input[2+row])] = row
    }
    pos, total, answer := 2+n, 0, i64(0)
    for q := 0; q < queries; q += 1 {
        if pos == int(length) || input[pos] < 0 || input[pos] > 256 { return -1 }
        count := int(input[pos]); pos += 1
        if count > 256-total || count > int(length)-pos { return -1 }
        cursor := 0
        matches := true
        for i := 0; i < count; i += 1 {
            symbol := input[pos+i]
            if symbol < 0 || symbol > 3 { return -1 }
            if matches {
                found := next[cursor][int(symbol)]
                if found == n { matches = false } else { cursor = found+1 }
            }
        }
        if matches { answer += i64(q+1) }
        pos += count; total += count
    }
    return if pos == int(length) then answer else -1
}
