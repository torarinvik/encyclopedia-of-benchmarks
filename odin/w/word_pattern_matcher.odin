package word_pattern_matcher
import "core:c"

match_at :: proc "contextless" (pattern, text: [^]i64, plen, tlen, pi, ti: int, starts, sizes: [^]int) -> bool {
    if pi == plen do return ti == tlen
    symbol := int(pattern[pi] - 32)
    if sizes[symbol] >= 0 {
        size := sizes[symbol]
        if ti + size > tlen do return false
        for j := 0; j < size; j += 1 { if text[ti+j] != text[starts[symbol]+j] do return false }
        return match_at(pattern, text, plen, tlen, pi+1, ti+size, starts, sizes)
    }
    for size := 1; ti+size <= tlen; size += 1 {
        used := false
        for other := 0; other < 95; other += 1 {
            if sizes[other] == size {
                same := true
                for j := 0; j < size; j += 1 { if text[ti+j] != text[starts[other]+j] { same = false; break } }
                if same { used = true; break }
            }
        }
        if used do continue
        starts[symbol] = ti; sizes[symbol] = size
        if match_at(pattern, text, plen, tlen, pi+1, ti+size, starts, sizes) do return true
        sizes[symbol] = -1
    }
    return false
}

@(export) word_pattern_matcher :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    _ = output; _ = capacity
    if input == nil || length < 2 || input[0] < 0 || input[0] > 8 do return -1
    plen := int(input[0]); if length < uint(plen+2) do return -1
    text_index := plen+1
    if input[text_index] < 0 || input[text_index] > 32 do return -1
    tlen := int(input[text_index]); if length != uint(text_index+1+tlen) do return -1
    for i := 0; i < plen; i += 1 { if input[i+1] < 32 || input[i+1] > 126 do return -1 }
    for i := 0; i < tlen; i += 1 { if input[text_index+1+i] < 32 || input[text_index+1+i] > 126 do return -1 }
    starts: [95]int; sizes: [95]int
    for i := 0; i < 95; i += 1 { starts[i] = -1; sizes[i] = -1 }
    if match_at(&input[1], &input[text_index+1], plen, tlen, 0, 0, &starts[0], &sizes[0]) do return 1
    return 0
}
