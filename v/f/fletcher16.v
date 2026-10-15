module fletcher16

const max_bytes = 4096

@[export: 'fletcher16']
pub fn fletcher16(input &i64, length usize) i64 {
    if length > max_bytes { return -1 }
    unsafe {
        mut sum1 := u32(0)
        mut sum2 := u32(0)
        for index in 0 .. int(length) {
            byte := input[index]
            if byte < 0 || byte > 127 { return -1 }
            sum1 = (sum1 + u32(byte)) % 255
            sum2 = (sum2 + sum1) % 255
        }
        return i64((sum2 << 8) | sum1)
    }
}
