module mirror

const max_length = 256

@[export: 'mirror']
pub fn mirror(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 1 || length > max_length + 1 { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > max_length { return -1 }
        n := int(input[0])
        if length != usize(n + 1) { return -1 }
        for i in 0 .. n { if input[i + 1] < 1 || input[i + 1] > 127 { return -1 } }
        if unsafe { output == nil } || capacity < usize(n + 1) { return -2 }
        mut buffer := [257]u8{}
        for i in 0 .. n { buffer[i] = u8(input[i + 1]) }
        buffer[n] = 0
        mut logical_length := 0
        for buffer[logical_length] != 0 { logical_length++ }
        if logical_length > 0 {
            mut left := 0
            mut right := logical_length - 1
            for left <= right {
                temporary := buffer[left]
                buffer[left] = buffer[right]
                buffer[right] = temporary
                left++
                if right == 0 { break }
                right--
            }
        }
        for i in 0 .. n { output[i] = buffer[i] }
        output[n] = 0
        return i64(n)
    }
}
