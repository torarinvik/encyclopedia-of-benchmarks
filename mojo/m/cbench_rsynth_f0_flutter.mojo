# Independently written bounded RSynth flutter profile; see package notice.
from std.ffi import c_size_t
from std.math import sin
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cbench_rsynth_f0_flutter")
fn cbench_rsynth_f0_flutter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let f0 = input[0]
    let flutter = input[1]
    let time = input[2]
    if f0 < 0 or f0 > 20000 or flutter < 0 or flutter > 100 or time < 0 or time > 1000000: return -1
    let pi = Float64(3.1415927)
    let t = Float64(time)
    let a = Float64(flutter) / 50.0
    let b = Float64(f0 // 10) / 100.0
    let c = sin(2.0 * pi * 12.7 * t)
    let d = sin(2.0 * pi * 7.1 * t)
    let e = sin(2.0 * pi * 4.7 * t)
    return f0 + Int64(a * b * (c + d + e) * 10.0)
