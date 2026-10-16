// Go Problem17: sum byte lengths after splitting on ASCII space.
module word_length_sum

@[export: 'word_length_sum']
pub fn word_length_sum(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    mut total := i64(0)
    unsafe {
        for index in 0 .. int(length) {
            value := values[index]
            if value < 0 || value > 255 { return -1 }
            if value != 32 { total++ }
        }
    }
    return total
}
