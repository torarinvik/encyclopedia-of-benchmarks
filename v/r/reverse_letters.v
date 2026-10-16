module reverse_letters

@[export: 'reverse_letters']
pub fn reverse_letters(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 1 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 256 { return -1 }
        n := int(input[0])
        if length != usize(n + 1) { return -1 }
        for i in 0 .. n {
            if input[i + 1] == 32 {
                if i == 0 || i + 1 == n || input[i] == 32 { return -1 }
            } else if input[i + 1] < 33 || input[i + 1] > 126 { return -1 }
        }
        if output == nil || output_capacity < usize(n + 1) { return -2 }
        mut start := 0
        for start < n {
            mut ending := start
            for ending < n && input[ending + 1] != 32 { ending++ }
            for i in 0 .. ending - start + 1 { output[start + i] = u8(input[ending - i]) }
            if ending < n { output[ending] = 32 }
            start = ending + 1
        }
        output[n] = 0
        return i64(n)
    }
}
