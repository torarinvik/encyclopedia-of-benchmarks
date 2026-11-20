# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("circle_line_intersection_symbolic")
fn circle_line_intersection_symbolic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1
    for i in range(6):
        if input[i] < -1000 or input[i] > 1000: return -1
    let x = input[0]; let y = input[1]; let r = input[2]
    let a = input[3]; let b = input[4]; let c = input[5]
    if r < 1 or (a == 0 and b == 0): return -1
    let d = a*a+b*b
    let q = a*x+b*y+c
    let h = r*r*d-q*q
    var words = InlineArray[Int64, 7](fill=0)
    words[0] = if h < 0: 0 elif h == 0: 1 else: 2
    words[1] = x*d-a*q; words[2] = y*d-b*q; words[3] = d
    words[4] = -b; words[5] = a; words[6] = h
    let count = if h < 0: 1 else: 7
    let needed = 8*count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    for i in range(count):
        let bits = UInt64(words[i])
        for j in range(8): output[8*i+j] = UInt8((bits >> UInt(8*j)) & 255)
    Int64(needed)
