module main

const max_text_length = 128
const max_requested_count = i64(64)
const checksum_base = i64(300000)

@[export: 'substring']
pub fn substring(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > max_text_length + 2 { return -1 }
        text_length := int(length) - 2
        start := values[0]
        requested := values[1]
        if start < 0 || start > i64(text_length) || requested < 0 || requested > max_requested_count { return -1 }
        for i in 0 .. text_length { if values[i + 2] < 1 || values[i + 2] > 127 { return -1 } }
        remaining := text_length - int(start)
        mut count := int(requested)
        if count == 0 && remaining > 0 { count = 1 }
        if count > remaining { count = remaining }
        mut checksum := i64(0)
        for i in 0 .. count { checksum += i64(i + 1) * values[int(start) + i + 2] }
        return i64(count) * checksum_base + checksum
    }
}
