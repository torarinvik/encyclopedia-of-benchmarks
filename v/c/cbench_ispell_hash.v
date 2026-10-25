module cbench_ispell_hash
const max_word_bytes = 64
fn upper_ascii(c u32) u32 { if c >= 97 && c <= 122 { return c - 32 }; return c }
@[export: 'cbench_ispell_hash']
pub fn cbench_ispell_hash(values &i64, length usize) i64 {
    if length == 0 || length > max_word_bytes + 1 { return -1 }
    table_size := unsafe { values[0] }
    if table_size < 1 || table_size > 2147483647 { return -1 }
    count := length - 1
    for i in 0 .. count { c := unsafe { values[i + 1] }; if c < 1 || c > 127 { return -1 } }
    mut h := u32(0)
    initial := if count < 4 { count } else { 4 }
    for i in 0 .. initial { h = (h << 8) | upper_ascii(u32(unsafe { values[i + 1] })) }
    for i in initial .. count { h = (h << 5) | (h >> 27); h ^= upper_ascii(u32(unsafe { values[i + 1] })) }
    return i64(u64(h) % u64(table_size))
}
