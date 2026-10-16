package elementary
import "core:c"
@(export)
elementary :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, capacity: c.size_t) -> i64 {
    if v == nil || n < 2 || n > 129 do return -1
    count := v[0]
    if count < 1 || count > 128 || n != c.size_t(count + 1) || v[1] != 0 do return -1
    for i := 1; i < int(n); i += 1 { if v[i] != 0 && v[i] != 1 do return -1 }
    if capacity < c.size_t(count) || out == nil do return -2
    for i := 0; i < int(count); i += 1 {
        l := u32(0); if i > 0 do l = u32(v[i])
        c0 := u32(v[i+1]); r := u32(0); if i+1 < int(count) do r = u32(v[i+2])
        out[i] = u8((30 >> (l*4+c0*2+r)) & 1)
    }
    return count
}
