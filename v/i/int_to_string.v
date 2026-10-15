module int_to_string

const max_value = 65535
const symbols = '0123456789abcdef'.bytes()

@[export: 'int_to_string']
pub fn int_to_string(packed i64, output &u8, output_capacity usize) i64 {
    if packed < 0 { return -1 }
    value := packed / 15
    base := packed % 15 + 2
    if value > max_value { return -1 }
    mut digits := [16]u8{}
    mut count := 0
    mut remaining := value
    for {
        digits[count] = symbols[int(remaining % base)]
        count++
        remaining /= base
        if remaining == 0 { break }
    }
    required := count + 1
    if output_capacity < required { return -2 }
    unsafe {
        for index in 0 .. count { output[index] = digits[count-index-1] }
        output[count] = 0
    }
    return i64(required)
}
