from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt, abs

fn one_sided_jacobi_svd_impl(input: view[Int64]) -> Int64:
    if input.len() < 3 or input.len() > 39: return -1
    let m0 = input[0]
    let n0 = input[1]
    if n0 < 1 or n0 > 6 or m0 < n0 or m0 > 6: return -1
    let m = Int(m0)
    let n = Int(n0)
    if input.len() != 2 + m * n: return -1
    var a = InlineArray[Float64, 36](fill=0.0)
    for r in range(m):
        for col in range(n):
            let x = input[2 + r * n + col]
            if x < -8 or x > 8: return -1
            a[r * n + col] = Float64(x)
    var converged = False
    for sweep in range(128):
        var changed = False
        for p in range(n):
            for q in range(p + 1, n):
                var alpha: Float64 = 0.0
                var beta: Float64 = 0.0
                var gamma: Float64 = 0.0
                for r in range(m):
                    let x = a[r * n + p]
                    let y = a[r * n + q]
                    alpha += x * x
                    beta += y * y
                    gamma += x * y
                if alpha == 0.0 or beta == 0.0 or abs(gamma) <= 1.0e-14 * sqrt(alpha * beta): continue
                let tau = (beta - alpha) / (2.0 * gamma)
                let t = 1.0 if tau == 0.0 else (1.0 if tau > 0.0 else -1.0) / (abs(tau) + sqrt(1.0 + tau * tau))
                let c = 1.0 / sqrt(1.0 + t * t)
                let s = c * t
                for r in range(m):
                    let x = a[r * n + p]
                    let y = a[r * n + q]
                    a[r * n + p] = c * x - s * y
                    a[r * n + q] = s * x + c * y
                changed = True
        if not changed:
            converged = True
            break
    if not converged: return -1
    var sigma = InlineArray[Float64, 6](fill=0.0)
    for col in range(n):
        for r in range(m): sigma[col] += a[r * n + col] * a[r * n + col]
        sigma[col] = sqrt(sigma[col])
    for i in range(n):
        for j in range(i + 1, n):
            if sigma[j] > sigma[i]:
                let t = sigma[i]
                sigma[i] = sigma[j]
                sigma[j] = t
    var signature: Float64 = 0.0
    for i in range(n): signature += Float64(i + 1) * sigma[i]
    return Int64(signature * 1000.0 + 0.5)

@export("one_sided_jacobi_svd")
fn one_sided_jacobi_svd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 39: return -1
    return one_sided_jacobi_svd_impl(input[0:Int(length)])
