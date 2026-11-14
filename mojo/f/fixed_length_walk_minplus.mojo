# Uncompiled exact-length shortest-walk draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fixed_length_walk_minplus")
fn fixed_length_walk_minplus(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 261: return -100000002
    let nv = input[0]
    var k = input[1]
    let source = input[2]
    let target = input[3]
    if nv < 1 or nv > 16 or k < 0 or k > 1000000 or source < 0 or source >= nv or target < 0 or target >= nv: return -100000002
    let n = Int(nv)
    if length != c_size_t(4+n*n): return -100000002
    let inf: Int64 = 1000000000000000
    var matrix = InlineArray[Int64, 256](fill=inf)
    var next = InlineArray[Int64, 256](fill=inf)
    var distance = InlineArray[Int64, 16](fill=inf)
    var temp = InlineArray[Int64, 16](fill=inf)
    for i in range(n):
        for j in range(n):
            let w = input[4+i*n+j]
            if w != 1000000 and (w < -100 or w > 100): return -100000002
            if w != 1000000: matrix[16*i+j] = w
    distance[Int(source)] = 0
    while k > 0:
        if k % 2 != 0:
            for j in range(n):
                temp[j] = inf
                for i in range(n):
                    let edge = matrix[16*i+j]
                    if distance[i] != inf and edge != inf and distance[i]+edge < temp[j]:
                        temp[j] = distance[i]+edge
            for i in range(n): distance[i] = temp[i]
        k //= 2
        if k > 0:
            for i in range(n):
                for j in range(n):
                    let index = 16*i+j
                    next[index] = inf
                    for p in range(n):
                        let a = matrix[16*i+p]
                        let b = matrix[16*p+j]
                        if a != inf and b != inf and a+b < next[index]: next[index] = a+b
            for i in range(n):
                for j in range(n): matrix[16*i+j] = next[16*i+j]
    if distance[Int(target)] == inf: return -100000001
    return distance[Int(target)]
