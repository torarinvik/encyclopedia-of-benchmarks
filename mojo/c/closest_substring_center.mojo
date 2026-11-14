from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("closest_substring_center")
fn closest_substring_center(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 44: return -1
    let nv = input[0]
    let mv = input[1]
    let lv = input[2]
    let qv = input[3]
    if nv < 1 or nv > 4 or mv < 1 or mv > 10 or lv < 1 or lv > 8 or lv > mv or (qv != 2 and qv != 3): return -1
    let n = Int(nv)
    let m = Int(mv)
    let l = Int(lv)
    let q = Int(qv)
    if length != c_size_t(4+n*m): return -1
    for i in range(n*m):
        if input[4+i] < 0 or input[4+i] >= qv: return -1
    let bytes = 8*(l+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var total = 1
    for _ in range(l): total *= q
    var best = l+1
    var candidate = List[Int](capacity=8)
    var center = List[Int](capacity=8)
    for _ in range(8):
        candidate.append(0)
        center.append(0)
    for code in range(total):
        var value = code
        var position = l
        while position > 0:
            position -= 1
            candidate[position] = value%q
            value //= q
        var radius = 0
        for row in range(n):
            var row_best = l+1
            for start in range(m-l+1):
                var distance = 0
                for col in range(l):
                    if candidate[col] != Int(input[4+row*m+start+col]): distance += 1
                row_best = min(row_best, distance)
            radius = max(radius, row_best)
        if radius < best:
            best = radius
            for col in range(l): center[col] = candidate[col]
    put_word(output, 0, Int64(best))
    for col in range(l): put_word(output, 8*(col+1), Int64(center[col]))
    return Int64(bytes)
