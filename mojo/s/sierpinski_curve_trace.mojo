from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ORDER = 2
comptime MAX_PARSEABLE_INPUT = 2
comptime MAX_STACK = 64

fn push(mut stack: InlineArray[UInt8, 128], mut top: Int,
        symbol: UInt8, level: UInt8) -> None:
    stack[top * 2] = symbol
    stack[top * 2 + 1] = level
    top += 1

fn emit_curve(order: UInt8, output: UnsafePointer[UInt8, MutAnyOrigin]) -> Int:
    var stack = InlineArray[UInt8, 128](fill=UInt8(0))
    var top = 0
    var written = 0
    push(stack, top, UInt8(5), UInt8(0)); push(stack, top, UInt8(3), order)
    push(stack, top, UInt8(7), UInt8(0)); push(stack, top, UInt8(2), order)
    push(stack, top, UInt8(9), UInt8(0)); push(stack, top, UInt8(1), order)
    push(stack, top, UInt8(11), UInt8(0)); push(stack, top, UInt8(0), order)
    while top > 0:
        top -= 1
        let symbol = stack[top * 2]
        let level = stack[top * 2 + 1]
        if symbol >= 4:
            output[written] = symbol - 4
            written += 1
        elif level > 0:
            let child = level - 1
            if symbol == 0:
                push(stack,top,UInt8(0),child); push(stack,top,UInt8(5),UInt8(0)); push(stack,top,UInt8(3),child)
                push(stack,top,UInt8(12),UInt8(0)); push(stack,top,UInt8(1),child); push(stack,top,UInt8(11),UInt8(0)); push(stack,top,UInt8(0),child)
            elif symbol == 1:
                push(stack,top,UInt8(1),child); push(stack,top,UInt8(11),UInt8(0)); push(stack,top,UInt8(0),child)
                push(stack,top,UInt8(18),UInt8(0)); push(stack,top,UInt8(2),child); push(stack,top,UInt8(9),UInt8(0)); push(stack,top,UInt8(1),child)
            elif symbol == 2:
                push(stack,top,UInt8(2),child); push(stack,top,UInt8(9),UInt8(0)); push(stack,top,UInt8(1),child)
                push(stack,top,UInt8(16),UInt8(0)); push(stack,top,UInt8(3),child); push(stack,top,UInt8(7),UInt8(0)); push(stack,top,UInt8(2),child)
            else:
                push(stack,top,UInt8(3),child); push(stack,top,UInt8(7),UInt8(0)); push(stack,top,UInt8(2),child)
                push(stack,top,UInt8(14),UInt8(0)); push(stack,top,UInt8(0),child); push(stack,top,UInt8(5),UInt8(0)); push(stack,top,UInt8(3),child)
    return written

@export("sierpinski_curve_trace")
fn sierpinski_curve_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > MAX_PARSEABLE_INPUT:
        return -1
    if length != 1:
        return -1
    let value = input[0]
    if value < 0 or value > MAX_ORDER:
        return -1
    let order = Int(value)
    var required = 4
    for _ in range(order):
        required *= 4
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    return Int64(emit_curve(UInt8(order), output))
