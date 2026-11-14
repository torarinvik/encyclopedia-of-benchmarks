from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("crust_pole_triangle_filter")
fn crust_pole_triangle_filter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 51: return -1
    if input[0] < 3 or input[0] > 8 or input[1] < 1 or input[1] > 4 or input[0] + input[1] > 12: return -1
    if input[2] < 0 or input[2] > 16 or Int(length) != 3 + 3 * Int(input[2]): return -1
    let sample_count = input[0]
    let vertex_count = input[0] + input[1]
    let facets = Int(input[2])
    var triangles = InlineArray[Int64, 48](fill=0)
    var count = 0
    for i in range(facets):
        var a = input[3 + 3 * i]
        var b = input[4 + 3 * i]
        var c = input[5 + 3 * i]
        if a < 0 or b < 0 or c < 0 or a >= vertex_count or b >= vertex_count or c >= vertex_count: return -1
        if a == b or a == c or b == c: return -1
        if a >= sample_count or b >= sample_count or c >= sample_count: continue
        if a > b:
            let temp = a
            a = b
            b = temp
        if b > c:
            let temp = b
            b = c
            c = temp
        if a > b:
            let temp = a
            a = b
            b = temp
        var duplicate = False
        for j in range(count):
            if triangles[3 * j] == a and triangles[3 * j + 1] == b and triangles[3 * j + 2] == c: duplicate = True
        if duplicate: continue
        var pos = count
        while pos > 0:
            let prior = 3 * (pos - 1)
            if triangles[prior] < a or (triangles[prior] == a and triangles[prior + 1] < b) or (triangles[prior] == a and triangles[prior + 1] == b and triangles[prior + 2] < c): break
            for j in range(3): triangles[3 * pos + j] = triangles[prior + j]
            pos -= 1
        triangles[3 * pos] = a
        triangles[3 * pos + 1] = b
        triangles[3 * pos + 2] = c
        count += 1
    let words = 1 + 3 * count
    let bytes = 8 * words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(words):
        var value = Int64(count)
        if i > 0: value = triangles[i - 1]
        var bits = UInt64(value)
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
