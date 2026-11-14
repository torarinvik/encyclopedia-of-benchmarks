from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("closest_string_center")
fn closest_string_center(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 51: return -1
    let nv = input[0]
    let mv = input[1]
    let qv = input[2]
    if nv < 1 or nv > 6 or mv < 1 or mv > 8 or (qv != 2 and qv != 3): return -1
    let n = Int(nv)
    let m = Int(mv)
    let q = Int(qv)
    if length != c_size_t(3+n*m): return -1
    for i in range(n*m):
        if input[3+i] < 0 or input[3+i] >= qv: return -1
    let bytes = 8*(m+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var total = 1
    for _ in range(m): total *= q
    var best = m+1
    var candidate = List[Int](capacity=8)
    var center = List[Int](capacity=8)
    for _ in range(8):
        candidate.append(0)
        center.append(0)
    for code in range(total):
        var value = code
        var position = m
        while position > 0:
            position -= 1
            candidate[position] = value%q
            value //= q
        var radius = 0
        for row in range(n):
            var distance = 0
            for col in range(m):
                if candidate[col] != Int(input[3+row*m+col]): distance += 1
            radius = max(radius, distance)
        if radius < best:
            best = radius
            for col in range(m): center[col] = candidate[col]
    put_word(output, 0, Int64(best))
    for col in range(m): put_word(output, 8*(col+1), Int64(center[col]))
    return Int64(bytes)
