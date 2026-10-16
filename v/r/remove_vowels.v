module remove_vowels

@[export: 'remove_vowels']
pub fn remove_vowels(values &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if values == nil || length < 1 || length > 4097 || values[0] < 0 || values[0] > 4096 { return -1 }
        n := int(values[0]); if length != usize(n + 1) { return -1 }
        mut result := 0
        for i in 0 .. n {
            if values[i+1] < 0 || values[i+1] > 127 { return -1 }
            mut c := int(values[i+1]); if c >= 65 && c <= 90 { c += 32 }
            if c != 97 && c != 101 && c != 105 && c != 111 && c != 117 { result++ }
        }
        if usize(result) > capacity || (result > 0 && output == nil) { return -2 }
        mut written := 0
        for i in 0 .. n {
            mut c := int(values[i+1]); if c >= 65 && c <= 90 { c += 32 }
            if c != 97 && c != 101 && c != 105 && c != 111 && c != 117 { output[written] = u8(c); written++ }
        }
        return i64(written)
    }
}
