module longest_chunked_palindrome_decomposition

@[export: 'longest_chunked_palindrome_decomposition']
pub fn longest_chunked_palindrome_decomposition(text &i64, length usize) i64 {
    if length > 128 { return -1 }
    for index in 0 .. length {
        value := unsafe { text[index] }
        if value < 1 || value > 127 { return -1 }
    }
    mut left := usize(0)
    mut right := length
    mut chunks := i64(0)
    for left < right {
        remaining := right - left
        mut size := usize(1)
        mut matched := false
        for size <= remaining / 2 && !matched {
            mut equal := true
            mut offset := usize(0)
            for offset < size && equal {
                if unsafe { text[left + offset] } != unsafe { text[right - size + offset] } { equal = false }
                offset++
            }
            if equal {
                chunks += 2
                left += size
                right -= size
                matched = true
            } else {
                size++
            }
        }
        if !matched { return chunks + 1 }
    }
    return chunks
}
