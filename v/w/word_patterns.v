module word_patterns

@[export: 'word_patterns']
fn word_patterns(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 1 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 256 { return -1 }
        n := int(input[0])
        if length != usize(n + 1) { return -1 }
        mut first := []int{len:128, init:-1}
        mut next := 0
        mut pos := 0
        for i in 0 .. n {
            mut ch := input[i+1]
            if ch < 0 || ch > 127 { return -1 }
            if ch >= 97 && ch <= 122 { ch -= 32 }
            c := int(ch)
            if first[c] < 0 { first[c] = next; next++ }
        }
        if output == nil || output_capacity < usize(4*n+1) { return -2 }
        for i in 0 .. n { mut ch := input[i+1]; if ch>=97 && ch<=122 {ch-=32}; c:=int(ch); if i > 0 { output[pos] = u8(`.`); pos++ }
            mut value := first[c]
            mut digits := [3]u8{}
            mut count := 0
            for {
                digits[count] = u8(`0` + value%10)
                count++
                value /= 10
                if value == 0 { break }
            }
            for count > 0 { count--; output[pos] = digits[count]; pos++ }
        }
        output[pos] = 0
        return i64(pos)
    }
}
