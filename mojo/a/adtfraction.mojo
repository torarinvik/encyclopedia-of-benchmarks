from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn adtfraction_signed(bits: UInt32) -> Int32:
    if bits <= 2147483647:
        return Int32(bits)
    return Int32(Int64(bits) - 4294967296)

fn adtfraction_add(a: Int32, b: Int32) -> Int32:
    return adtfraction_signed(UInt32(a) + UInt32(b))

fn adtfraction_mul(a: Int32, b: Int32) -> Int32:
    return adtfraction_signed(UInt32(a) * UInt32(b))

fn adtfraction_pack(n: Int32, d: Int32) -> Int64:
    return Int64(n) * 4294967296 + Int64(UInt32(d))

@export("adtfraction")
fn adtfraction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5:
        return -1
    for i in range(5):
        if input[i] < -100000 or input[i] > 100000:
            return -1
    if input[0] < 0 or input[0] > 4:
        return -1
    let op = Int32(input[0])
    let n = Int32(input[1])
    let d = Int32(input[2])
    let m = Int32(input[3])
    let e = Int32(input[4])
    if op == 0:
        if d == 0 or e == 0:
            return -1
        let on = adtfraction_add(adtfraction_mul(d, m), adtfraction_mul(n, e))
        let od = adtfraction_mul(d, e)
        if od == 0:
            return -1
        return adtfraction_pack(on, od)
    if op == 1:
        if d == 0:
            return -1
        return adtfraction_pack(adtfraction_mul(n, m), d)
    if op == 2:
        if d == 0 or e == 0:
            return -1
        let od = adtfraction_mul(d, e)
        if od == 0:
            return -1
        return adtfraction_pack(adtfraction_mul(n, m), od)
    if op == 3:
        if n == 0:
            return -1
        return adtfraction_pack(d, n)
    if d == 0:
        return -1
    let value = Float32(n) / Float32(d)
    let bits = bitcast[UInt32](value)
    return Int64(bits)
