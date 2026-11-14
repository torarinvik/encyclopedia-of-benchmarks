# PolyBench unpivoted LU decomposition and triangular solves.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("polybench_ludcmp")
fn polybench_ludcmp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    let nv = input[0]
    if nv < 1 or nv > 64: return -1.0e300
    let n = Int(nv)
    var a = List[Float64](capacity=n*n)
    var product = List[Float64](capacity=n*n)
    var b = List[Float64](capacity=n)
    var x = List[Float64](capacity=n)
    var y = List[Float64](capacity=n)
    for i in range(n):
        b.append((Float64(i)+1.0)/Float64(n)/2.0+4.0)
        x.append(0.0); y.append(0.0)
        for j in range(n):
            var value = Float64(0.0)
            if j <= i: value = -Float64(j % n)/Float64(n)+1.0
            if j == i: value = 1.0
            a.append(value); product.append(0.0)
    for t in range(n):
        for r in range(n):
            for s in range(n): product[r*n+s] += a[r*n+t]*a[s*n+t]
    for i in range(n*n): a[i] = product[i]
    for i in range(n):
        for j in range(i):
            var value = a[i*n+j]
            for k in range(j): value -= a[i*n+k]*a[k*n+j]
            a[i*n+j] = value/a[j*n+j]
        for j in range(i,n):
            var value = a[i*n+j]
            for k in range(i): value -= a[i*n+k]*a[k*n+j]
            a[i*n+j] = value
    for i in range(n):
        var value = b[i]
        for j in range(i): value -= a[i*n+j]*y[j]
        y[i] = value
    var i = n
    while i > 0:
        i -= 1
        var value = y[i]
        for j in range(i+1,n): value -= a[i*n+j]*x[j]
        x[i] = value/a[i*n+i]
    var total = Float64(0.0)
    for j in range(n): total += x[j]
    return total
