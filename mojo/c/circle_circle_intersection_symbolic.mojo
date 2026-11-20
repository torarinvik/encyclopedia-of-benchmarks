# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("circle_circle_intersection_symbolic")
fn circle_circle_intersection_symbolic(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t,
        out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 6: return -1
    for i in range(6):
        if v[i] < -1000 or v[i] > 1000: return -1
    if v[2] < 1 or v[5] < 1: return -1
    let dx=v[3]-v[0]
    let dy=v[4]-v[1]
    let d=dx*dx+dy*dy
    var words=InlineArray[Int64, 7](fill=0)
    var count=1
    if d == 0:
        if v[2] == v[5]: words[0]=3
    else:
        let t=d+v[2]*v[2]-v[5]*v[5]
        let h=4*v[2]*v[2]*d-t*t
        if h >= 0:
            let den=2*d
            count=7
            words[0]=if h == 0: 1 else: 2
            words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t
            words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h
    let needed=8*count
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(needed): return -2
    for i in range(count):
        let bits=UInt64(words[i])
        for j in range(8): out[8*i+j]=UInt8((bits >> UInt(8*j)) & 255)
    Int64(needed)
