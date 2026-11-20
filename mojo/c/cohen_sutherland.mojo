from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const INVALID_RESULT = -1.0e300
const SCALE = 1_000_000.0
const MAX_COORDINATE_MICRO: Int64 = 1_000_000_000
const LEFT: Int64 = 1
const RIGHT: Int64 = 2
const BOTTOM: Int64 = 4
const TOP: Int64 = 8

fn region_code(
    x: Float64, y: Float64,
    x_min: Float64, y_min: Float64, x_max: Float64, y_max: Float64,
) -> Int64:
    var code: Int64 = 0
    if x < x_min:
        code |= LEFT
    elif x > x_max:
        code |= RIGHT
    if y < y_min:
        code |= BOTTOM
    elif y > y_max:
        code |= TOP
    return code

@export("cohen_sutherland")
fn cohen_sutherland(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 9:
        return INVALID_RESULT

    let selector = values[0]
    if selector < 0 or selector > 4:
        return INVALID_RESULT
    for index in range(1, 9):
        let coordinate = values[index]
        if coordinate < -MAX_COORDINATE_MICRO or coordinate > MAX_COORDINATE_MICRO:
            return INVALID_RESULT

    let x_min = Float64(values[1]) / SCALE
    let y_min = Float64(values[2]) / SCALE
    let x_max = Float64(values[3]) / SCALE
    let y_max = Float64(values[4]) / SCALE
    if x_min >= x_max or y_min >= y_max:
        return INVALID_RESULT

    var x1 = Float64(values[5]) / SCALE
    var y1 = Float64(values[6]) / SCALE
    var x2 = Float64(values[7]) / SCALE
    var y2 = Float64(values[8]) / SCALE
    var code1 = region_code(x1, y1, x_min, y_min, x_max, y_max)
    var code2 = region_code(x2, y2, x_min, y_min, x_max, y_max)

    var accepted = false
    while True:
        if code1 == 0 and code2 == 0:
            accepted = true
            break
        if (code1 & code2) != 0:
            break

        let outside = if code1 != 0 then code1 else code2
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        if (outside & TOP) != 0:
            x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
            y = y_max
        elif (outside & BOTTOM) != 0:
            x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
            y = y_min
        elif (outside & RIGHT) != 0:
            y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
            x = x_max
        else:
            y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
            x = x_min

        if outside == code1:
            x1 = x
            y1 = y
            code1 = region_code(x1, y1, x_min, y_min, x_max, y_max)
        else:
            x2 = x
            y2 = y
            code2 = region_code(x2, y2, x_min, y_min, x_max, y_max)

    if selector == 4:
        return 1.0 if accepted else 0.0
    if not accepted:
        return INVALID_RESULT
    if selector == 0:
        return x1
    if selector == 1:
        return y1
    if selector == 2:
        return x2
    return y2
