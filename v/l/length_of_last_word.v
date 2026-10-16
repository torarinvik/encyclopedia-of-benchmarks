module length_of_last_word

@[export: 'length_of_last_word']
pub fn length_of_last_word(input &i64, length usize) i64 {
    if length < 1 || length > 129 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 128 || length != usize(input[0]) + 1 { return -1 }
        for i in 1 .. length { if input[i] < 0 || input[i] > 255 { return -1 } }
        mut index := int(input[0])
        for index > 0 && input[index] == 32 { index-- }
        mut word_length := i64(0)
        for index > 0 && input[index] != 32 {
            word_length++
            index--
        }
        return word_length
    }
}
