# Fixed-point replay of the rank-one noisy power method.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn noisy_trunc(value: Int64, divisor: Int64) -> Int64:
    if value < 0: return -((-value) // divisor)
    return value // divisor

@export("private_noisy_power_iteration")
fn private_noisy_power_iteration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 11 or length > 39: return -1
    let nv = input[0]
    let lv = input[1]
    let sigma = input[2]
    if nv < 2 or nv > 4 or lv < 1 or lv > 4 or sigma < 0 or sigma > 1000000 or length != c_size_t(3+nv*nv+nv+lv*nv): return -1
    let n = Int(nv)
    let rounds = Int(lv)
    var matrix = List[Int64](capacity=n*n)
    var vector = List[Int64](capacity=n)
    var noise = List[Int64](capacity=rounds*n)
    var y = List[Int64](capacity=n)
    for i in range(n*n):
        let value = input[3+i]
        if value < -1000000 or value > 1000000: return -1
        matrix.append(value)
    for i in range(n):
        for j in range(n):
            if matrix[i*n+j] != matrix[j*n+i]: return -1
    var norm = Int64(0)
    for i in range(n):
        let value = input[3+n*n+i]
        if value < -1000000 or value > 1000000: return -1
        vector.append(value); y.append(0)
        norm += value*value
    if norm != 1000000000000: return -1
    for i in range(rounds*n):
        let value = input[3+n*n+n+i]
        if value < -2000000 or value > 2000000: return -1
        noise.append(value)
    for step in range(rounds):
        var norm_squared = Int64(0)
        for i in range(n):
            var sum = sigma*noise[step*n+i]
            for j in range(n): sum += matrix[i*n+j]*vector[j]
            y[i] = noisy_trunc(sum,1000000)
            norm_squared += y[i]*y[i]
        if norm_squared == 0: return -1
        var low = Int64(0)
        var high = Int64(13000001)
        while low+1 < high:
            let middle = (low+high) // 2
            if middle <= norm_squared // middle: low = middle
            else: high = middle
        for i in range(n): vector[i] = noisy_trunc(y[i]*1000000,low)
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        for byte in range(8): output[8*i+byte] = UInt8((vector[i] >> (8*byte)) & 255)
    return Int64(bytes)
