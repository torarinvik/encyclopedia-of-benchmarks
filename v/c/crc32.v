module crc32
const max_length = 100001
const polynomial = i64(3988292384)
const initial = i64(4294967295)
@[export: 'crc32']
pub fn crc32(values &i64, length usize) i64 {
    if length > max_length || (length != 0 && values == nil) { return -1 }
    mut crc := initial
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < 0 || value > 255 { return -1 }
        crc ^= value
        for _ in 0 .. 8 {
            if (crc & 1) != 0 { crc = (crc >> 1) ^ polynomial } else { crc >>= 1 }
        }
    }
    return crc ^ initial
}
