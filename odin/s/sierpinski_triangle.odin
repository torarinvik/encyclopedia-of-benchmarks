package sierpinski_triangle

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := u64(value)
    for byte: usize = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

emit_segment :: proc "contextless" (output: [^]u8, position: ^usize,
    x0, y0, x1, y1: i64) {
    write_i64_le(output, position^, x0); position^ += 8
    write_i64_le(output, position^, y0); position^ += 8
    write_i64_le(output, position^, x1); position^ += 8
    write_i64_le(output, position^, y1); position^ += 8
}

draw_triangle :: proc "contextless" (output: [^]u8, position: ^usize,
    x1, y1, x2, y2, x3, y3, depth: i64) {
    emit_segment(output, position, x1, y1, x2, y2)
    emit_segment(output, position, x2, y2, x3, y3)
    emit_segment(output, position, x3, y3, x1, y1)
    if depth == 0 do return
    abx, aby := (x1 + x2) / 2, (y1 + y2) / 2
    acx, acy := (x1 + x3) / 2, (y1 + y3) / 2
    bcx, bcy := (x2 + x3) / 2, (y2 + y3) / 2
    draw_triangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1)
    draw_triangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1)
    draw_triangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1)
}

@(export, link_name="sierpinski_triangle")
sierpinski_triangle :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    depth := input[0]
    if depth < 0 || depth > 4 do return -1
    calls: usize = 1
    for level: i64 = 0; level < depth; level += 1 {
        calls = calls * 3 + 1
    }
    needed := calls * 96
    if needed > 11616 do return -1
    if output == nil || capacity < c.size_t(needed) do return -2
    position: usize = 0
    draw_triangle(output, &position, -2800, -2000, 0, 2800, 2800, -2000, depth)
    return i64(needed)
}
