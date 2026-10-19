from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn append_integer(value0: Int64, mut bytes: List[UInt8]):
    var value = value0
    if value < 0:
        bytes.append(45)
        value = -value
    var digits = List[UInt8](capacity=24)
    while True:
        digits.append(UInt8(value % 10))
        value /= 10
        if value == 0:
            break
    for i in range(len(digits)):
        bytes.append(UInt8(48 + digits[len(digits) - 1 - i]))

@export("adams_bashforth")
fn adams_bashforth(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4:
        return -1
    let order = values[0]
    let steps = values[1]
    if order < 2 or order > 5 or steps < 1 or steps > 4 or length != c_size_t(order + 2):
        return -1
    var x = List[Float64](length=14, fill=0.0)
    var y = List[Float64](length=14, fill=0.0)
    for i in range(order):
        if values[2 + i] < -100000 or values[2 + i] > 100000:
            return -1
        x[i] = Float64(i) * 0.25
        y[i] = Float64(values[2 + i]) / 100000.0
    var coeff = List[Int64](length=5, fill=0)
    var denominator: Int64 = 2
    if order == 2:
        coeff[0] = 3; coeff[1] = -1
    elif order == 3:
        coeff[0] = 23; coeff[1] = -16; coeff[2] = 5; denominator = 12
    elif order == 4:
        coeff[0] = 55; coeff[1] = -59; coeff[2] = 37; coeff[3] = -9; denominator = 24
    else:
        coeff[0] = 1901; coeff[1] = -2774; coeff[2] = -2616; coeff[3] = -1274; coeff[4] = 251; denominator = 720
    var iterations = steps
    if order == 3 or order == 5:
        iterations += 1
    let count = order + iterations
    for it in range(iterations):
        var weighted: Float64 = 0.0
        for off in range(order):
            let idx = count - iterations + it - 1 - off
            weighted += Float64(coeff[off]) * (x[idx] + y[idx])
        let idx = order + it
        y[idx] = y[idx - 1] + (0.25 / Float64(denominator)) * weighted
        x[idx] = x[idx - 1] + 0.25
    var encoded = List[UInt8](capacity=256)
    for i in range(count):
        if i != 0:
            encoded.append(44)
        append_integer(Int64(y[i] * 1000000.0), encoded)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(encoded)):
        return -2
    for i in range(len(encoded)):
        output[i] = encoded[i]
    return Int64(len(encoded))
