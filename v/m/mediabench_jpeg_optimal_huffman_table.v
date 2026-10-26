module mediabench_jpeg_optimal_huffman_table

const max_symbols = 20
const max_code_length = 32

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
@[export: 'mediabench_jpeg_optimal_huffman_table']
fn mediabench_jpeg_optimal_huffman_table(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 3 || length > 41 { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > max_symbols { return -1 }
        count := int(input[0])
        if length != usize(1 + 2 * count) { return -1 }
        for i in 0 .. count {
            symbol, frequency := input[1 + 2 * i], input[2 + 2 * i]
            if symbol < 0 || symbol > 255 || frequency < 1 || frequency > 1_000_000 { return -1 }
            for j in 0 .. i { if input[1 + 2 * j] == symbol { return -1 } }
        }
        output_size := 17 + count
        if output == nil || capacity < usize(output_size) { return -2 }
        mut freq := [257]i64{}
        mut code_size := [257]int{}
        mut others := [257]int{}
        mut bits := [max_code_length + 1]int{}
        for i in 0 .. 257 { others[i] = -1 }
        for i in 0 .. count { freq[int(input[1 + 2 * i])] = input[2 + 2 * i] }
        freq[256] = 1
        for {
            mut c1 := -1
            mut c2 := -1
            mut value := i64(1_000_000_000)
            for i in 0 .. 257 { if freq[i] != 0 && freq[i] <= value { value = freq[i]; c1 = i } }
            value = 1_000_000_000
            for i in 0 .. 257 { if freq[i] != 0 && freq[i] <= value && i != c1 { value = freq[i]; c2 = i } }
            if c2 < 0 { break }
            freq[c1] += freq[c2]
            freq[c2] = 0
            code_size[c1]++
            mut branch := c1
            for others[branch] >= 0 { branch = others[branch]; code_size[branch]++ }
            others[branch] = c2
            code_size[c2]++
            branch = c2
            for others[branch] >= 0 { branch = others[branch]; code_size[branch]++ }
        }
        for i in 0 .. 257 {
            if code_size[i] != 0 { if code_size[i] > max_code_length { return -1 }; bits[code_size[i]]++ }
        }
        for i := max_code_length; i > 16; i-- {
            for bits[i] > 0 {
                mut j := i - 2
                for j >= 0 && bits[j] == 0 { j-- }
                if j < 0 || bits[i] < 2 { return -1 }
                bits[i] -= 2
                bits[i - 1]++
                bits[j + 1] += 2
                bits[j]--
            }
        }
        mut longest := 16
        for longest > 0 && bits[longest] == 0 { longest-- }
        if longest == 0 { return -1 }
        bits[longest]--
        mut symbol_count := 0
        for size in 1 .. max_code_length + 1 { for symbol in 0 .. 256 { if code_size[symbol] == size { symbol_count++ } } }
        if symbol_count != count { return -1 }
        output[0] = u8(count)
        for i in 1 .. 17 { output[i] = u8(bits[i]) }
        mut used := 17
        for size in 1 .. max_code_length + 1 {
            for symbol in 0 .. 256 {
                if code_size[symbol] == size { output[used] = u8(symbol); used++ }
            }
        }
        return i64(used)
    }
}
