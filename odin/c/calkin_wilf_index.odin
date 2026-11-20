// Uncompiled indexed Calkin–Wilf fraction draft.
package calkin_wilf_index
import "core:c"
@(export)
calkin_wilf_index :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    raw := input[0]
    if raw < 1 || raw >= (i64(1) << 62) do return -1
    if output == nil || capacity < 16 do return -2
    index := u64(raw)
    high := u64(1)
    for high <= index / 2 { high *= 2 }
    numerator, denominator := u64(1), u64(1)
    high /= 2
    for high != 0 {
        if (index & high) != 0 { numerator += denominator } else { denominator += numerator }
        high /= 2
    }
    for i := 0; i < 8; i += 1 {
        output[i] = u8((numerator >> uint(8*i)) & 255)
        output[i+8] = u8((denominator >> uint(8*i)) & 255)
    }
    return 16
}
