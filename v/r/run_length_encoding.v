module run_length_encoding

// Encode runs as an unambiguous decimal count followed by an ASCII byte.
@[export: 'run_length_encoding']
pub fn run_length_encoding(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 66 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        if value < 1 || value > 127 || (value >= 48 && value <= 57) { return -1 }
    }

    mut encoded_length := usize(0)
    mut index := usize(0)
    for index < length {
        mut ending := index + 1
        for ending < length && unsafe { input[ending] == input[index] } { ending++ }
        count := ending - index
        if count >= 10 { encoded_length += 3 } else { encoded_length += 2 }
        index = ending
    }
    if output_capacity < encoded_length { return -2 }

    mut write_index := usize(0)
    index = 0
    for index < length {
        mut ending := index + 1
        for ending < length && unsafe { input[ending] == input[index] } { ending++ }
        count := ending - index
        if count >= 10 {
            unsafe { output[write_index] = u8(48 + count / 10) }
            write_index++
        }
        unsafe { output[write_index] = u8(48 + count % 10) }
        write_index++
        unsafe { output[write_index] = u8(input[index]) }
        write_index++
        index = ending
    }
    return i64(write_index)
}
