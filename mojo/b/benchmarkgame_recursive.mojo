from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

fn ack(x: Int64, y: Int64) -> Int64:
    if x == 0: return y+1
    if y == 0: return ack(x-1, 1)
    return ack(x-1, ack(x, y-1))

fn fib_int(n: Int64) -> Int64:
    if n < 2: return 1
    return fib_int(n-2)+fib_int(n-1)

fn fib_float(n: Float64) -> Float64:
    if n < 2.0: return 1.0
    return fib_float(n-2.0)+fib_float(n-1.0)

fn tak_int(x: Int64, y: Int64, z: Int64) -> Int64:
    if y >= x: return z
    return tak_int(tak_int(x-1,y,z), tak_int(y-1,z,x), tak_int(z-1,x,y))

fn tak_float(x: Float64, y: Float64, z: Float64) -> Float64:
    if y >= x: return z
    return tak_float(tak_float(x-1.0,y,z), tak_float(y-1.0,z,x), tak_float(z-1.0,x,y))

fn append_text(mut buffer: List[UInt8], text: String):
    for byte in text.as_bytes(): buffer.append(byte)

fn append_number(mut buffer: List[UInt8], value: Int64):
    var reversed = List[UInt8](capacity=20)
    var remaining = value
    while True:
        reversed.append(UInt8(48+remaining%10))
        remaining //= 10
        if remaining == 0: break
    var i = len(reversed)
    while i > 0:
        i -= 1
        buffer.append(reversed[i])

@export("benchmarkgame_recursive")
fn benchmarkgame_recursive(n: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if n < 0 or n > 10: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var staged = List[UInt8](capacity=89)
    append_text(staged, "Ack(3,")
    append_number(staged, n+1)
    append_text(staged, "): ")
    append_number(staged, ack(3, n+1))
    append_text(staged, "\nFib(")
    append_number(staged, 28+n)
    append_text(staged, ".0): ")
    append_number(staged, Int64(fib_float(Float64(28+n))))
    append_text(staged, ".0\nTak(")
    append_number(staged, 3*n)
    append_text(staged, ",")
    append_number(staged, 2*n)
    append_text(staged, ",")
    append_number(staged, n)
    append_text(staged, "): ")
    append_number(staged, tak_int(3*n, 2*n, n))
    append_text(staged, "\nFib(3): ")
    append_number(staged, fib_int(3))
    append_text(staged, "\nTak(3.0,2.0,1.0): ")
    append_number(staged, Int64(tak_float(3.0, 2.0, 1.0)))
    append_text(staged, ".0\n")
    if capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
