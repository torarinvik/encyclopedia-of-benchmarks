from std.collections import List
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn spectral_entry(i: Int, j: Int) -> Float64:
    let sum = i + j
    return 1.0 / Float64(sum * (sum + 1) // 2 + i + 1)

fn spectral_ata(n: Int, values: List[Float64], mut result: List[Float64],
        mut temporary: List[Float64]):
    for i in range(n):
        var total = Float64(0)
        for j in range(n): total += spectral_entry(i, j) * values[j]
        temporary[i] = total
    for i in range(n):
        var total = Float64(0)
        for j in range(n): total += spectral_entry(j, i) * temporary[j]
        result[i] = total

@export("spectral_norm")
fn spectral_norm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    if input[0] < 1 or input[0] > 64: return -1.0e300
    let n = Int(input[0])
    var u = List[Float64](length=n, fill=1.0)
    var v = List[Float64](length=n, fill=0.0)
    var temporary = List[Float64](length=n, fill=0.0)
    for _ in range(10):
        spectral_ata(n, u, v, temporary)
        spectral_ata(n, v, u, temporary)
    var uv = Float64(0)
    var vv = Float64(0)
    for i in range(n):
        uv += u[i] * v[i]
        vv += v[i] * v[i]
    return sqrt(uv / vv)
