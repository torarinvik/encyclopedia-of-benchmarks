package print_amatrix_in_spiral_order

import "core:c"

mix :: proc "contextless" (h: u32, b: u8) -> u32 { return u32((u64(h ^ u32(b)) * 16777619) & 0xFFFFFFFF) }
feed :: proc "contextless" (h0: u32, x: u32) -> u32 {
    h := h0
    for shift := 0; shift < 32; shift += 8 { h = mix(h, u8(x >> u32(shift))) }
    return h
}

@(export)
print_amatrix_in_spiral_order :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
    if v == nil || n < 3 || n > 66 || v[0] < 1 || v[0] > 8 || v[1] < 1 || v[1] > 8 || n != c.size_t(2 + v[0] * v[1]) do return -1
    rows, cols := int(v[0]), int(v[1])
    for i := 2; i < int(n); i += 1 { if v[i] < -2_147_483_648 || v[i] > 2_147_483_647 do return -1 }
    top, bottom, left, right := 0, rows - 1, 0, cols - 1
    h := u32(2166136261)
    for top <= bottom && left <= right {
        for c := left; c <= right; c += 1 { h = feed(h, u32(i32(v[2 + top * cols + c]))) }
        top += 1
        for r := top; r <= bottom; r += 1 { h = feed(h, u32(i32(v[2 + r * cols + right]))) }
        if right == 0 { break }
        right -= 1
        if top <= bottom {
            for c := right; c >= left; c -= 1 { h = feed(h, u32(i32(v[2 + bottom * cols + c]))) }
            if bottom == 0 { break }
            bottom -= 1
        }
        if left <= right {
            for r := bottom; r >= top; r -= 1 { h = feed(h, u32(i32(v[2 + r * cols + left]))) }
            left += 1
        }
    }
    return i64(h)
}
