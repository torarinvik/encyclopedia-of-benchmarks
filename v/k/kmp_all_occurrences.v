const max_text_length = 256
const max_pattern_length = 64
const max_input_length = 322

@[export: 'kmp_all_occurrences']
pub fn kmp_all_occurrences(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > max_input_length { return -1 }
        text_length_value := values[0]
        pattern_length_value := values[1]
        if text_length_value < 0 || text_length_value > max_text_length ||
            pattern_length_value < 1 || pattern_length_value > max_pattern_length { return -1 }
        text_length := int(text_length_value)
        pattern_length := int(pattern_length_value)
        if length != usize(2 + text_length + pattern_length) { return -1 }
        for i := 0; i < text_length + pattern_length; i++ {
            value := values[2 + i]
            if value < 0 || value > 127 { return -1 }
        }
        pattern_offset := 2 + text_length

        mut prefix := [64]int{}
        for i := 1; i < pattern_length; i++ {
            mut matched := prefix[i - 1]
            for matched > 0 && values[pattern_offset + i] != values[pattern_offset + matched] {
                matched = prefix[matched - 1]
            }
            if values[pattern_offset + i] == values[pattern_offset + matched] { matched++ }
            prefix[i] = matched
        }

        mut matches := [256]int{}
        mut match_count := 0
        mut matched := 0
        for i := 0; i < text_length; i++ {
            for matched > 0 && values[2 + i] != values[pattern_offset + matched] {
                matched = prefix[matched - 1]
            }
            if values[2 + i] == values[pattern_offset + matched] { matched++ }
            if matched == pattern_length {
                matches[match_count] = i + 1 - pattern_length
                match_count++
                matched = prefix[matched - 1]
            }
        }

        output_bytes := match_count * 8
        if output == nil || output_capacity < usize(output_bytes) { return -2 }
        for i := 0; i < match_count; i++ {
            bits := u64(matches[i])
            for byte := 0; byte < 8; byte++ {
                output[i * 8 + byte] = u8((bits >> u64(byte * 8)) & 255)
            }
        }
        return i64(output_bytes)
    }
}
