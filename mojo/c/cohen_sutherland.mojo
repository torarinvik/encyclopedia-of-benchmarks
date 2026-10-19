from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn cohen_code(x: Float64, y: Float64, xmin: Float64, ymin: Float64, xmax: Float64, ymax: Float64) -> Int64:
    var code: Int64 = 0
    if x < xmin: code |= 1
    elif x > xmax: code |= 2
    if y < ymin: code |= 4
    elif y > ymax: code |= 8
    return code

@export("cohen_sutherland")
fn cohen_sutherland(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 9: return -1.0e300
    let selector = values[0]
    if selector < 0 or selector > 4: return -1.0e300
    for i in range(1, 9):
        if values[i] < -1000000000 or values[i] > 1000000000: return -1.0e300
    let xmin = Float64(values[1]) / 1000000.0
    let ymin = Float64(values[2]) / 1000000.0
    let xmax = Float64(values[3]) / 1000000.0
    let ymax = Float64(values[4]) / 1000000.0
    if xmin >= xmax or ymin >= ymax: return -1.0e300
    var x1 = Float64(values[5]) / 1000000.0
    var y1 = Float64(values[6]) / 1000000.0
    var x2 = Float64(values[7]) / 1000000.0
    var y2 = Float64(values[8]) / 1000000.0
    var code1 = cohen_code(x1, y1, xmin, ymin, xmax, ymax)
    var code2 = cohen_code(x2, y2, xmin, ymin, xmax, ymax)
    var accepted = False
    while True:
        if code1 == 0 and code2 == 0:
            accepted = True
            break
        if (code1 & code2) != 0: break
        let outside = code1 if code1 != 0 else code2
        var x: Float64 = 0.0
        var y: Float64 = 0.0
        if (outside & 8) != 0:
            x = x1 + (x2 - x1) * (ymax - y1) / (y2 - y1)
            y = ymax
        elif (outside & 4) != 0:
            x = x1 + (x2 - x1) * (ymin - y1) / (y2 - y1)
            y = ymin
        elif (outside & 2) != 0:
            y = y1 + (y2 - y1) * (xmax - x1) / (x2 - x1)
            x = xmax
        else:
            y = y1 + (y2 - y1) * (xmin - x1) / (x2 - x1)
            x = xmin
        if outside == code1:
            x1 = x
            y1 = y
            code1 = cohen_code(x1, y1, xmin, ymin, xmax, ymax)
        else:
            x2 = x
            y2 = y
            code2 = cohen_code(x2, y2, xmin, ymin, xmax, ymax)
    if selector == 4: return 1.0 if accepted else 0.0
    if not accepted: return -1.0e300
    if selector == 0: return x1
    if selector == 1: return y1
    if selector == 2: return x2
    return y2
