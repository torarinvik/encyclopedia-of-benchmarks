package shannon_fano_compressor

import "core:c"

MAX_TEXT :: 16
MAX_SYMBOLS :: 16
MAX_CODE :: 15
MAX_OUTPUT :: 514

make_codes :: proc(symbols: [^]u8, count: int, freq: [^]f64, prefix: [^]u8, depth: int,
                  codes: [^]u8, lengths: [^]u8) -> bool {
    if count == 1 {
        for i in 0..<depth { codes[int(symbols[0])*MAX_CODE+i] = prefix[i] }
        lengths[int(symbols[0])] = u8(depth)
        return true
    }
    total: f64 = 0
    for i in 0..<count { total += freq[int(symbols[i])] }
    capacity := 0.5 * total
    running: f64 = 0
    left: [MAX_SYMBOLS]u8
    right: [MAX_SYMBOLS]u8
    nl, nr := 0, 0
    for i in 0..<count {
        symbol := symbols[i]
        if running + freq[int(symbol)] <= capacity {
            left[nl] = symbol; nl += 1; running += freq[int(symbol)]
        } else { right[nr] = symbol; nr += 1 }
    }
    if nl == 0 || nr == 0 || depth >= MAX_CODE do return false
    prefix[depth] = u8('0')
    if !make_codes(&left[0], nl, freq, prefix, depth+1, codes, lengths) do return false
    prefix[depth] = u8('1')
    return make_codes(&right[0], nr, freq, prefix, depth+1, codes, lengths)
}

@(export)
shannon_fano_compressor :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input_length > 18 || (input == nil && input_length != 0) || (input != nil && input_length == 0) do return -1
    text_length := 0
    if input != nil {
        if input[0] < 0 || input[0] > MAX_TEXT do return -1
        text_length = int(input[0])
        if input_length != c.size_t(text_length+1) do return -1
    }
    text: [MAX_TEXT]u8
    symbols: [MAX_SYMBOLS]u8
    counts: [128]int
    seen: [128]bool
    symbol_count := 0
    for i in 0..<text_length {
        value := input[i+1]
        if value < 0 || value > 127 do return -1
        s := int(value)
        text[i] = u8(s)
        if !seen[s] { seen[s] = true; symbols[symbol_count] = u8(s); symbol_count += 1 }
        counts[s] += 1
    }
    freq: [128]f64
    if text_length > 0 { for s in 0..<128 { freq[s] = (1.0*f64(counts[s]))/f64(text_length) } }
    codes: [128*MAX_CODE]u8
    lengths: [128]u8
    if symbol_count == 1 { codes[int(symbols[0])*MAX_CODE] = u8('1'); lengths[int(symbols[0])] = 1 }
    else if symbol_count > 1 {
        prefix: [MAX_CODE]u8
        if !make_codes(&symbols[0], symbol_count, &freq[0], &prefix[0], 0, &codes[0], &lengths[0]) do return -1
    }
    staged: [MAX_OUTPUT]u8
    n, compressed_length := 0, 0
    for i in 0..<text_length { compressed_length += int(lengths[int(text[i])]) }
    staged[n] = u8(compressed_length); n += 1
    for i in 0..<text_length {
        s := int(text[i])
        for j in 0..<int(lengths[s]) { staged[n] = codes[s*MAX_CODE+j]; n += 1 }
    }
    staged[n] = u8(symbol_count); n += 1
    for s in 0..<128 {
        if lengths[s] != 0 {
            staged[n] = u8(s); n += 1
            staged[n] = lengths[s]; n += 1
            for j in 0..<int(lengths[s]) { staged[n] = codes[s*MAX_CODE+j]; n += 1 }
        }
    }
    if output == nil || capacity < c.size_t(n) do return -2
    for i in 0..<n { output[i] = staged[i] }
    return i64(n)
}
