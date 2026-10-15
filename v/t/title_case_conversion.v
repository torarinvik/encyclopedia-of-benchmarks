module title_case_conversion

@[export: 'title_case_conversion']
pub fn title_case_conversion(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 1 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 256 { return -1 }
        n := int(input[0])
        if length != usize(n + 1) { return -1 }
        for i in 0 .. n {
            value := input[i + 1]
            is_letter := (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
            if is_letter { continue }
            if value == 32 && i > 0 && i + 1 < n && input[i] != 32 { continue }
            return -1
        }
        if unsafe { output == nil } || output_capacity < usize(n + 1) { return -2 }
        mut at_word_start := true
        for i in 0 .. n {
            mut value := input[i + 1]
            if value == 32 {
                output[i] = 32
                at_word_start = true
            } else if at_word_start {
                if value >= 97 && value <= 122 { value -= 32 }
                output[i] = u8(value)
                at_word_start = false
            } else {
                if value >= 65 && value <= 90 { value += 32 }
                output[i] = u8(value)
            }
        }
        output[n] = 0
        return i64(n)
    }
}
