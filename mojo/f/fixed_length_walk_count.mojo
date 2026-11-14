# Uncompiled exact-length walk counting draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fixed_length_walk_count")
fn fixed_length_walk_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 261: return -1
    let nv = input[0]
    var k = input[1]
    let source = input[2]
    let target = input[3]
    if nv < 1 or nv > 16 or k < 0 or k > 1000000000 or source < 0 or source >= nv or target < 0 or target >= nv: return -1
    let n = Int(nv)
    if length != c_size_t(4+n*n): return -1
    let modulus: Int64 = 1000000007
    var matrix = InlineArray[Int64, 256](fill=0)
    var next = InlineArray[Int64, 256](fill=0)
    var vector = InlineArray[Int64, 16](fill=0)
    var temp = InlineArray[Int64, 16](fill=0)
    for i in range(n):
        for j in range(n):
            let value = input[4+i*n+j]
            if value < 0 or value > 100: return -1
            matrix[16*i+j] = value
    vector[Int(source)] = 1
    while k > 0:
        if k % 2 != 0:
            for j in range(n):
                temp[j] = 0
                for i in range(n): temp[j] = (temp[j]+vector[i]*matrix[16*i+j]) % modulus
            for i in range(n): vector[i] = temp[i]
        k //= 2
        if k > 0:
            for i in range(n):
                for j in range(n):
                    let index = 16*i+j
                    next[index] = 0
                    for p in range(n): next[index] = (next[index]+matrix[16*i+p]*matrix[16*p+j]) % modulus
            for i in range(n):
                for j in range(n): matrix[16*i+j] = next[16*i+j]
    return vector[Int(target)]
