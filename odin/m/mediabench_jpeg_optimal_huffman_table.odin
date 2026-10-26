package mediabench_jpeg_optimal_huffman_table

import "core:c"

MAX_SYMBOLS :: 20
MAX_CLEN :: 32

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
@(export)
mediabench_jpeg_optimal_huffman_table :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 41 do return -1
    if input[0] < 1 || input[0] > MAX_SYMBOLS do return -1
    count := int(input[0])
    if length != c.size_t(1+2*count) do return -1
    for i := 0; i < count; i += 1 {
        symbol, frequency := input[1+2*i], input[2+2*i]
        if symbol < 0 || symbol > 255 || frequency < 1 || frequency > 1_000_000 do return -1
        for j := 0; j < i; j += 1 { if input[1+2*j] == symbol do return -1 }
    }
    output_size := 17+count
    if output == nil || capacity < c.size_t(output_size) do return -2
    freq: [257]i64
    code_size: [257]int
    others: [257]int
    bits: [MAX_CLEN+1]int
    for i := 0; i <= 256; i += 1 { others[i] = -1 }
    for i := 0; i < count; i += 1 { freq[int(input[1+2*i])] = input[2+2*i] }
    freq[256] = 1
    for {
        c1, c2 := -1, -1
        value := i64(1_000_000_000)
        for i := 0; i <= 256; i += 1 { if freq[i] != 0 && freq[i] <= value { value = freq[i]; c1 = i } }
        value = 1_000_000_000
        for i := 0; i <= 256; i += 1 { if freq[i] != 0 && freq[i] <= value && i != c1 { value = freq[i]; c2 = i } }
        if c2 < 0 do break
        freq[c1] += freq[c2]; freq[c2] = 0
        code_size[c1] += 1
        branch := c1
        for others[branch] >= 0 { branch = others[branch]; code_size[branch] += 1 }
        others[branch] = c2
        code_size[c2] += 1
        branch = c2
        for others[branch] >= 0 { branch = others[branch]; code_size[branch] += 1 }
    }
    for i := 0; i <= 256; i += 1 {
        if code_size[i] != 0 { if code_size[i] > MAX_CLEN do return -1; bits[code_size[i]] += 1 }
    }
    for i := MAX_CLEN; i > 16; i -= 1 {
        for bits[i] > 0 {
            j := i-2
            for j >= 0 && bits[j] == 0 { j -= 1 }
            if j < 0 || bits[i] < 2 do return -1
            bits[i] -= 2; bits[i-1] += 1; bits[j+1] += 2; bits[j] -= 1
        }
    }
    longest := 16
    for longest > 0 && bits[longest] == 0 { longest -= 1 }
    if longest == 0 do return -1
    bits[longest] -= 1
    symbol_count := 0
    for size := 1; size <= MAX_CLEN; size += 1 { for symbol := 0; symbol <= 255; symbol += 1 { if code_size[symbol] == size do symbol_count += 1 } }
    if symbol_count != count do return -1
    output[0] = u8(count)
    for i := 1; i <= 16; i += 1 { output[i] = u8(bits[i]) }
    used := 17
    for size := 1; size <= MAX_CLEN; size += 1 {
        for symbol := 0; symbol <= 255; symbol += 1 {
            if code_size[symbol] == size { output[used] = u8(symbol); used += 1 }
        }
    }
    return i64(used)
}
