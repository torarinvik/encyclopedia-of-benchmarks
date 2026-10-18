const max_text = 16
const max_symbols = 16
const max_code = 15
const max_output = 514

fn sf_make_codes(symbols &u8, count int, freq &f64, mut prefix &u8, depth int,
    mut codes &u8, mut lengths &u8) bool {
    unsafe {
        if count == 1 {
            s := int(symbols[0])
            for i in 0 .. depth { codes[s * max_code + i] = prefix[i] }
            lengths[s] = u8(depth)
            return true
        }
        mut total := 0.0
        for i in 0 .. count { total += freq[int(symbols[i])] }
        capacity := 0.5 * total
        mut running := 0.0
        mut left := [max_symbols]u8{}
        mut right := [max_symbols]u8{}
        mut nl := 0
        mut nr := 0
        for i in 0 .. count {
            symbol := symbols[i]
            if running + freq[int(symbol)] <= capacity {
                left[nl] = symbol
                nl++
                running += freq[int(symbol)]
            } else {
                right[nr] = symbol
                nr++
            }
        }
        if nl == 0 || nr == 0 || depth >= max_code { return false }
        prefix[depth] = `0`
        if !sf_make_codes(&left[0], nl, freq, mut prefix, depth + 1, mut codes, mut lengths) { return false }
        prefix[depth] = `1`
        return sf_make_codes(&right[0], nr, freq, mut prefix, depth + 1, mut codes, mut lengths)
    }
}

@[export: 'shannon_fano_compressor']
pub fn shannon_fano_compressor(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input_length > 18 || (input == nil && input_length != 0) || (input != nil && input_length == 0) { return -1 }
        mut text_length := 0
        if input != nil {
            if input[0] < 0 || input[0] > max_text { return -1 }
            text_length = int(input[0])
            if input_length != usize(text_length + 1) { return -1 }
        }
        mut text := [max_text]u8{}
        mut symbols := [max_symbols]u8{}
        mut counts := [128]int{}
        mut seen := [128]bool{}
        mut symbol_count := 0
        for i in 0 .. text_length {
            value := input[i + 1]
            if value < 0 || value > 127 { return -1 }
            s := int(value)
            text[i] = u8(s)
            if !seen[s] { seen[s] = true; symbols[symbol_count] = u8(s); symbol_count++ }
            counts[s]++
        }
        mut freq := [128]f64{}
        if text_length > 0 { for s in 0 .. 128 { freq[s] = (1.0 * f64(counts[s])) / f64(text_length) } }
        mut codes := [128 * max_code]u8{}
        mut lengths := [128]u8{}
        if symbol_count == 1 { codes[int(symbols[0]) * max_code] = `1`; lengths[int(symbols[0])] = 1 }
        else if symbol_count > 1 {
            mut prefix := [max_code]u8{}
            if !sf_make_codes(&symbols[0], symbol_count, &freq[0], mut prefix[0], 0, mut codes[0], mut lengths[0]) { return -1 }
        }
        mut staged := [max_output]u8{}
        mut n := 0
        mut compressed_length := 0
        for i in 0 .. text_length { compressed_length += int(lengths[int(text[i])]) }
        staged[n] = u8(compressed_length)
        n++
        for i in 0 .. text_length {
            s := int(text[i])
            for j in 0 .. int(lengths[s]) { staged[n] = codes[s * max_code + j]; n++ }
        }
        staged[n] = u8(symbol_count)
        n++
        for s in 0 .. 128 {
            if lengths[s] != 0 {
                staged[n] = u8(s); n++
                staged[n] = lengths[s]; n++
                for j in 0 .. int(lengths[s]) { staged[n] = codes[s * max_code + j]; n++ }
            }
        }
        if output == nil || capacity < usize(n) { return -2 }
        for i in 0 .. n { output[i] = staged[i] }
        return i64(n)
    }
}
