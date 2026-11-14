# PolyBench alternating-direction implicit sweeps.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polybench_adi")
fn polybench_adi(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]
    let tv = input[1]
    if nv < 1 or nv > 32 or tv < 1 or tv > 20: return -1
    let n = Int(nv)
    let steps = Int(tv)
    let cells = n*n
    var u = List[Float64](capacity=cells)
    var v = List[Float64](capacity=cells)
    var p = List[Float64](capacity=cells)
    var q = List[Float64](capacity=cells)
    for i in range(n):
        for j in range(n):
            u.append(Float64(i+n-j)/Float64(n))
            v.append(0.0); p.append(0.0); q.append(0.0)
    let dx = Float64(1.0)/Float64(n)
    let dy = Float64(1.0)/Float64(n)
    let dt = Float64(1.0)/Float64(steps)
    let mul1 = Float64(2.0)*dt/(dx*dx)
    let mul2 = dt/(dy*dy)
    let a = -mul1/Float64(2.0)
    let b = Float64(1.0)+mul1
    let c = a
    let d = -mul2/Float64(2.0)
    let e = Float64(1.0)+mul2
    let f = d
    for _ in range(steps):
        for i in range(1,n-1):
            v[i] = 1.0; p[i*n] = 0.0; q[i*n] = v[i]
            for j in range(1,n-1):
                p[i*n+j] = -c/(a*p[i*n+j-1]+b)
                q[i*n+j] = (-d*u[j*n+i-1]+(1.0+2.0*d)*u[j*n+i]-f*u[j*n+i+1]-a*q[i*n+j-1])/(a*p[i*n+j-1]+b)
            v[(n-1)*n+i] = 1.0
            var j = n-1
            while j > 1:
                j -= 1
                v[j*n+i] = p[i*n+j]*v[(j+1)*n+i]+q[i*n+j]
        for i in range(1,n-1):
            u[i*n] = 1.0; p[i*n] = 0.0; q[i*n] = u[i*n]
            for j in range(1,n-1):
                p[i*n+j] = -f/(d*p[i*n+j-1]+e)
                q[i*n+j] = (-a*v[(i-1)*n+j]+(1.0+2.0*a)*v[i*n+j]-c*v[(i+1)*n+j]-d*q[i*n+j-1])/(d*p[i*n+j-1]+e)
            u[i*n+n-1] = 1.0
            var j = n-1
            while j > 1:
                j -= 1
                u[i*n+j] = p[i*n+j]*u[i*n+j+1]+q[i*n+j]
    let bytes = 8*cells
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(cells):
        let bits = bitcast[UInt64](u[i])
        for byte in range(8): output[8*i+byte] = UInt8((bits >> (8*byte)) & 255)
    return Int64(bytes)
