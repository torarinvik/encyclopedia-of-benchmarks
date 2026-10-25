package cbench_ispell_hash
import "core:c"
MAX_WORD_BYTES :: 64
upper_ascii :: proc(c: u32) -> u32 { if c >= 97 && c <= 122 do return c - 32; return c }
@(export)
cbench_ispell_hash :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > MAX_WORD_BYTES + 1 do return -1
    table_size := values[0]
    if table_size < 1 || table_size > 2_147_483_647 do return -1
    count := length - 1
    for i := c.size_t(0); i < count; i += 1 { if values[i+1] < 1 || values[i+1] > 127 do return -1 }
    h: u32 = 0
    initial := count
    if initial > 4 do initial = 4
    for i := c.size_t(0); i < initial; i += 1 { h = (h << 8) | upper_ascii(u32(values[i+1])) }
    for i := initial; i < count; i += 1 { h = (h << 5) | (h >> 27); h = h ^ upper_ascii(u32(values[i+1])) }
    return i64(u64(h) % u64(table_size))
}
