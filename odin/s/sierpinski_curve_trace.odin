package sierpinski_curve_trace

import "core:c"

MAX_ORDER :: 2
MAX_PARSEABLE_INPUT :: 2
MAX_STACK :: 64

Frame :: struct { symbol: u8, level: u8 }

push :: proc(stack: []Frame, top: ^int, symbol, level: u8) {
    stack[top^] = Frame{symbol = symbol, level = level}
    top^ += 1
}

emit_curve :: proc(order: u8, output: [^]u8) -> int {
    stack: [MAX_STACK]Frame
    top := 0
    written := 0
    push(stack[:], &top, 5, 0); push(stack[:], &top, 3, order)
    push(stack[:], &top, 7, 0); push(stack[:], &top, 2, order)
    push(stack[:], &top, 9, 0); push(stack[:], &top, 1, order)
    push(stack[:], &top, 11, 0); push(stack[:], &top, 0, order)
    for top > 0 {
        top -= 1
        frame := stack[top]
        if frame.symbol >= 4 {
            output[written] = frame.symbol - 4
            written += 1
            continue
        }
        if frame.level == 0 do continue
        child := frame.level - 1
        switch frame.symbol {
        case 0:
            push(stack[:],&top,0,child); push(stack[:],&top,5,0); push(stack[:],&top,3,child)
            push(stack[:],&top,12,0); push(stack[:],&top,1,child); push(stack[:],&top,11,0); push(stack[:],&top,0,child)
        case 1:
            push(stack[:],&top,1,child); push(stack[:],&top,11,0); push(stack[:],&top,0,child)
            push(stack[:],&top,18,0); push(stack[:],&top,2,child); push(stack[:],&top,9,0); push(stack[:],&top,1,child)
        case 2:
            push(stack[:],&top,2,child); push(stack[:],&top,9,0); push(stack[:],&top,1,child)
            push(stack[:],&top,16,0); push(stack[:],&top,3,child); push(stack[:],&top,7,0); push(stack[:],&top,2,child)
        case:
            push(stack[:],&top,3,child); push(stack[:],&top,7,0); push(stack[:],&top,2,child)
            push(stack[:],&top,14,0); push(stack[:],&top,0,child); push(stack[:],&top,5,0); push(stack[:],&top,3,child)
        }
    }
    return written
}

@(export)
sierpinski_curve_trace :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
    if input == nil || length == 0 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
    if length != 1 do return -1
    if input[0] < 0 || input[0] > MAX_ORDER do return -1
    order := int(input[0])
    required := 4
    for _ in 0..<order { required *= 4 }
    if output == nil || capacity < c.size_t(required) do return -2
    return i64(emit_curve(u8(order), output))
}
