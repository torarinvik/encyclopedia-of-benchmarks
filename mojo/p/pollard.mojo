from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn gcd_p(a0: Int64, b0: Int64) -> Int64:
    var a = a0; var b = b0
    while b != 0: let r = a % b; a = b; b = r
    return a
fn next_p(x: Int64, n: Int64) -> Int64: return (x * x + 1) % n

@export("pollard")
fn pollard(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 1 or v[0] < 2 or v[0] > 111155: return -1
    let m = v[0]; var x = 2; var y = 2; var d = 1
    while d == 1:
        x = next_p(x, m); y = next_p(next_p(y, m), m)
        let diff = if x >= y: x-y else: y-x
        d = gcd_p(diff, m)
    return if d == m: 0 else: d
