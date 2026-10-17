const max_list_length = 64
const max_input_length = 130

@[export: 'sublist_search']
pub fn sublist_search(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > max_input_length { return -1 }
        main_count_value := values[0]
        pattern_count_value := values[1]
        if main_count_value < 0 || main_count_value > max_list_length ||
            pattern_count_value < 0 || pattern_count_value > max_list_length { return -1 }
        main_count := int(main_count_value)
        pattern_count := int(pattern_count_value)
        if length != usize(2 + main_count + pattern_count) { return -1 }
        for i := 0; i < main_count + pattern_count; i++ {
            value := values[2 + i]
            if value < 0 || value > 2147483647 { return -1 }
        }

        if main_count == 0 || pattern_count == 0 || pattern_count > main_count { return 0 }
        pattern_offset := 2 + main_count
        for start := 0; start <= main_count - pattern_count; start++ {
            mut matched := 0
            for matched < pattern_count && values[2 + start + matched] == values[pattern_offset + matched] {
                matched++
            }
            if matched == pattern_count { return 1 }
        }
        return 0
    }
}
