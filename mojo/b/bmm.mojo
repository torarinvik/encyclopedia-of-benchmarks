# Bounded VersaBench derivative; retain benchmarks/b/bmm/LICENSE.
from std.collections import List, InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("versabench_bmm")
fn versabench_bmm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]
    let bv = input[1]
    if nv < 1 or nv > 128 or bv < 1 or bv > nv or nv % bv != 0: return -1
    let n = Int(nv)
    let block = Int(bv)
    var a = List[Float32](capacity=n*n)
    var b = List[Float32](capacity=n*n)
    var product = List[Float32](capacity=n*n)
    for _ in range(n*n):
        a.append(Float32(0)); b.append(Float32(0)); product.append(Float32(0))
    var seed: UInt64 = 1
    for i in range(n):
        for j in range(1024):
            seed = (seed * 1664525 + 1013904223) & 0xffffffff
            let ra = (seed >> 16) & 0x7fff
            seed = (seed * 1664525 + 1013904223) & 0xffffffff
            let rb = (seed >> 16) & 0x7fff
            if j < n:
                a[i*n+j] = Float32((ra >> ((j-i) & 31)) & 15)
                b[i*n+j] = Float32((rb << ((i+j) & 31)) & 15)
    var ti = 0
    while ti < n:
        var tj = 0
        while tj < n:
            var tk = 0
            while tk < n:
                for i in range(ti, ti+block):
                    for j in range(tj, tj+block):
                        for k in range(tk, tk+block):
                            product[i*n+j] += a[i*n+k] * b[k*n+j]
                tk += block
            tj += block
        ti += block
    var total = Float32(0)
    ti = 0
    while ti < n:
        var tj = 0
        while tj < n:
            var subtotal = Float32(0)
            for i in range(ti, ti+block):
                for j in range(tj, tj+block): subtotal += product[i*n+j]
            total += subtotal
            tj += block
        ti += block
    var digits = InlineArray[UInt8, 10]()
    var value = UInt64(total)
    var digit_count = 0
    while True:
        digits[digit_count] = UInt8(value % 10) + 48
        digit_count += 1
        value //= 10
        if value == 0: break
    let required = 12 + digit_count + 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var used = 0
    for byte in "final sum = ".as_bytes():
        output[used] = byte
        used += 1
    while digit_count > 0:
        digit_count -= 1
        output[used] = digits[digit_count]
        used += 1
    for byte in ".000000\n".as_bytes():
        output[used] = byte
        used += 1
    return Int64(used)
