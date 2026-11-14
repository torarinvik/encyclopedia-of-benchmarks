from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("vector_scheduling")
fn vector_scheduling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 83: return -1
    let nv = input[0]; let mv = input[1]; let dv = input[2]
    if nv < 1 or nv > 16 or mv < 1 or mv > 8 or dv < 1 or dv > 4: return -1
    let n = Int(nv); let m = Int(mv); let d = Int(dv)
    if length != c_size_t(3+n+n*d): return -1
    var choices = List[Int](capacity=n)
    for i in range(n):
        let choice = input[3+i]
        if choice < 0 or choice >= mv: return -1
        choices.append(Int(choice))
    var loads = List[Int64](capacity=m*d)
    for _ in range(m*d): loads.append(0)
    for i in range(n):
        for q in range(d):
            let value = input[3+n+i*d+q]
            if value < 0 or value > 1000: return -1
            loads[choices[i]*d+q] += value
    var makespan = Int64(0)
    for value in loads:
        if value > makespan: makespan = value
    let words = 3+m*d
    let bytes = 8*words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(words):
        var value = mv
        if i == 1: value = dv
        elif i == 2: value = makespan
        elif i >= 3: value = loads[i-3]
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
