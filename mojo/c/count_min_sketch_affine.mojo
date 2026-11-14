from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("count_min_sketch_affine")
fn count_min_sketch_affine(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 59: return -1
    let dv = input[0]
    let wv = input[1]
    let qv = input[2]
    if dv < 1 or dv > 4 or wv < 1 or wv > 8 or qv < 0 or qv > 16: return -1
    let depth = Int(dv)
    let width = Int(wv)
    let operations = Int(qv)
    let start = 3 + 2 * depth
    if length != c_size_t(start + 3 * operations): return -1
    let prime = Int64(2147483647)
    for row in range(depth):
        let a = input[3 + 2 * row]
        let b = input[4 + 2 * row]
        if a < 1 or a >= prime or b < 0 or b >= prime: return -1
    var queries = 0
    for op in range(operations):
        let kind = input[start + 3 * op]
        let key = input[start + 3 * op + 1]
        let weight = input[start + 3 * op + 2]
        if key < 0 or key > 1000000: return -1
        if kind == 0:
            if weight < 1 or weight > 1000000: return -1
        elif kind == 1:
            if weight != 0: return -1
            queries += 1
        else:
            return -1
    let required = queries * 8
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var table = List[Int64](capacity=32)
    for _ in range(32): table.append(0)
    var answers = List[Int64](capacity=queries)
    for op in range(operations):
        let kind = input[start + 3 * op]
        let key = input[start + 3 * op + 1]
        let weight = input[start + 3 * op + 2]
        var minimum = Int64(16000000)
        for row in range(depth):
            let a = input[3 + 2 * row]
            let b = input[4 + 2 * row]
            let column = Int(((a * key + b) % prime) % wv)
            let index = row * width + column
            if kind == 0:
                table[index] += weight
            elif table[index] < minimum:
                minimum = table[index]
        if kind == 1:
            answers.append(minimum)
    for index in range(queries):
        for byte in range(8):
            output[8 * index + byte] = UInt8((answers[index] >> (8 * byte)) & 255)
    return Int64(required)
