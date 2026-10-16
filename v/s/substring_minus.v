module main

const max_text_length = 128
const checksum_base = i64(1100000)

@[export: 'substring_minus']
pub fn substring_minus(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 1 || length > max_text_length { return -1 }
        for i in 0 .. int(length) { if values[i] < 1 || values[i] > 127 { return -1 } }
        count := int(length) - 1
        mut checksum := i64(0)
        for i in 0 .. count { checksum += i64(i + 1) * values[i] }
        return i64(count) * checksum_base + checksum
    }
}
