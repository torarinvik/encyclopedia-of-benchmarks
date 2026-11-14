# Independent bounded implementation; see package LICENSE for NBench terms.
from std.collections import List
from std.ffi import c_size_t
from std.math import cos, isfinite, pow, sin
from std.memory import ImmutAnyOrigin, UnsafePointer

fn nbench_fourier_term(x: Float64, omega: Float64, kind: Int) -> Float64:
    let base = pow(x+1.0,x)
    if kind == 0: return base
    if kind == 1: return base*cos(omega*x)
    return base*sin(omega*x)

fn nbench_fourier_integrate(omega: Float64, kind: Int) -> Float64:
    let dx = Float64(2.0)/Float64(200.0)
    var x = Float64(0.0)
    var result = nbench_fourier_term(0.0,omega,kind)/2.0
    for _ in range(198):
        x += dx
        result += nbench_fourier_term(x,omega,kind)
    return (result+nbench_fourier_term(2.0,omega,kind)/2.0)*dx

@export("nbench_fourier_coefficients")
fn nbench_fourier_coefficients(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid = Float64(-1.0e300)
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return invalid
    let nv = input[0]
    if nv < 1 or nv > 16: return invalid
    let n = Int(nv)
    var a = List[Float64](length=n, fill=0.0)
    var b = List[Float64](length=n, fill=0.0)
    a[0] = nbench_fourier_integrate(0.0,0)/2.0
    for i in range(1,n):
        let omega = Float64(3.1415926535897932)*Float64(i)
        a[i] = nbench_fourier_integrate(omega,1)
        b[i] = nbench_fourier_integrate(omega,2)
    var result = Float64(0.0)
    for i in range(n): result += Float64(i+1)*a[i]
    for i in range(1,n): result += Float64(i)*b[i]
    if not isfinite(result): return invalid
    return result
