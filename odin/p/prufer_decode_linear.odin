// Uncompiled monotone-cursor Prüfer decoder draft.
package prufer_decode_linear
import "core:c"
pdl_write :: proc "contextless" (output: [^]u8, offset: int, value: int) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { output[offset+i] = u8((bits >> uint(8*i)) & 255) }
}
@(export)
prufer_decode_linear :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 4096 do return -1
    nv := input[0]
    if nv < 2 || nv > 4096 || length != c.size_t(nv-1) do return -1
    n := int(nv)
    count: [4096]int = {}
    for i := 1; i < int(length); i += 1 {
        if input[i] < 0 || input[i] >= nv do return -1
        count[int(input[i])] += 1
    }
    needed := 16*(n-1)
    if output == nil || capacity < c.size_t(needed) do return -2
    cursor := n-1
    for count[cursor] != 0 { cursor -= 1 }
    leaf := cursor
    for i := 1; i < int(length); i += 1 {
        v := int(input[i])
        pdl_write(output, 16*(i-1), leaf); pdl_write(output, 16*(i-1)+8, v)
        count[leaf] = -1; count[v] -= 1
        if count[v] == 0 && v > cursor { leaf = v } else {
            cursor -= 1
            for count[cursor] != 0 { cursor -= 1 }
            leaf = cursor
        }
    }
    other := 0
    for other == leaf || count[other] != 0 { other += 1 }
    pdl_write(output, 16*(n-2), leaf); pdl_write(output, 16*(n-2)+8, other)
    return i64(needed)
}
