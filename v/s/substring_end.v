module main

const max_text_length = 128
const checksum_base = i64(1100000)

@[export: 'substring_end']
pub fn substring_end(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 1 || length > max_text_length + 1 { return -1 }
        text_length := int(length) - 1
        start := values[0]
        if start < 0 || start > i64(text_length) { return -1 }
        for i in 0 .. text_length { if values[i + 1] < 1 || values[i + 1] > 127 { return -1 } }
        count := text_length - int(start)
        mut checksum := i64(0)
        for i in 0 .. count { checksum += i64(i + 1) * values[int(start) + i + 1] }
        return i64(count) * checksum_base + checksum
    }
}
