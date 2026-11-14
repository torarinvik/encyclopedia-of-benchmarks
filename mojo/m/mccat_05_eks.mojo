# Copyright (C) 1996 McGill University.
# Copyright (C) 1996 McCAT System Group.
# Copyright (C) 1996 ACAPS Benchmark Administrator, benadmin@acaps.cs.mcgill.ca.
# Independently implemented bounded profile; see the package README for the notice.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import ceil, floor, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn eks_abs(x: Float64) -> Float64:
    return -x if x < 0.0 else x

fn eks_rotation(a: Float64, b: Float64) -> (Float64, Float64):
    if b == 0.0: return (0.0, 1.0)
    if eks_abs(b) > eks_abs(a):
        let t = -a / b
        let s = 1.0 / sqrt(1.0 + t * t)
        return (s, s * t)
    let t = -b / a
    let c = 1.0 / sqrt(1.0 + t * t)
    return (c * t, c)

fn eks_apply(inout a: InlineArray[Float64, 64], n: Int, i: Int, j: Int,
             first: Int, last: Int, s: Float64, c: Float64):
    for k in range(first, last + 1):
        let x = a[i * n + k]
        let y = a[j * n + k]
        a[i * n + k] = c * x - s * y
        a[j * n + k] = s * x + c * y
    for k in range(first, last + 1):
        let x = a[k * n + i]
        let y = a[k * n + j]
        a[k * n + i] = c * x - s * y
        a[k * n + j] = s * x + c * y

fn eks_reduce(inout a: InlineArray[Float64, 64], n: Int, bandwidth: Int):
    var width = bandwidth
    while width >= 2:
        for j in range(n - width):
            let (s, c) = eks_rotation(a[j * n + j + width - 1], a[j * n + j + width])
            eks_apply(a, n, j + width - 1, j + width, j, min(j + 2 * width, n - 1), s, c)
            var m = j + width
            while m < n - width:
                let (s2, c2) = eks_rotation(a[(m - 1) * n + m + width - 1], a[(m - 1) * n + m + width])
                eks_apply(a, n, m + width - 1, m + width, m - 1, min(m + 2 * width, n - 1), s2, c2)
                m += width
        width -= 1

fn eks_qr(inout a: InlineArray[Float64, 64], n: Int) -> Bool:
    var sweeps = 0
    while True:
        for i in range(n - 1):
            if eks_abs(a[(i + 1) * n + i]) < (eks_abs(a[i * n + i]) + eks_abs(a[(i + 1) * n + i + 1])) * 1.0e-10:
                a[(i + 1) * n + i] = 0.0
                a[i * n + i + 1] = 0.0
        var q = n - 1
        while q > 0 and a[(q - 1) * n + q] == 0.0: q -= 1
        if q == 0: return True
        sweeps += 1
        if sweeps > 4096: return False
        var p = q
        while p > 0 and a[(p - 1) * n + p] != 0.0: p -= 1
        let d = (a[(q - 1) * n + q - 1] - a[q * n + q]) / 2.0
        let off = a[q * n + q - 1]
        let t = off * off
        let sign: Float64 = -1.0 if d < 0.0 else 1.0
        let shift = a[q * n + q] - t / (d + sign * sqrt(d * d + t))
        var x = a[p * n + p] - shift
        var z = a[(p + 1) * n + p]
        for i in range(p, q):
            let (s, c) = eks_rotation(x, z)
            let first = i - 1 if i > p else p
            let last = min(q, i + 2)
            eks_apply(a, n, i, i + 1, first, last, s, c)
            if i < q - 1:
                x = a[(i + 1) * n + i]
                z = a[(i + 2) * n + i]

@export("mccat_05_eks")
fn mccat_05_eks(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let raw_n = input[0]
    let raw_width = input[1]
    if raw_n < 3 or raw_n > 8 or raw_width < 2 or raw_width > 5 or raw_width >= raw_n: return -1
    let n = Int(raw_n)
    let bandwidth = Int(raw_width)
    if Int(length) != 2 + n * n: return -1
    var matrix = InlineArray[Float64, 64](fill=0.0)
    for row in range(n):
        for col in range(n):
            let v = input[2 + row * n + col]
            if v < -1000000 or v > 1000000: return -1
            if row > col and v != input[2 + col * n + row]: return -1
            if (row - col > bandwidth or col - row > bandwidth) and v != 0: return -1
            matrix[row * n + col] = Float64(v) / 1000000.0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(4 * n): return -2
    eks_reduce(matrix, n, bandwidth)
    if not eks_qr(matrix, n): return -1
    var eigenvalues = InlineArray[Float64, 8](fill=0.0)
    for i in range(n): eigenvalues[i] = matrix[i * n + i]
    for i in range(1, n):
        let value = eigenvalues[i]
        var j = i
        while j > 0 and (eks_abs(value) > eks_abs(eigenvalues[j - 1]) or
              (eks_abs(value) == eks_abs(eigenvalues[j - 1]) and value < eigenvalues[j - 1])):
            eigenvalues[j] = eigenvalues[j - 1]
            j -= 1
        eigenvalues[j] = value
    var staged = InlineArray[UInt8, 32](fill=0)
    for i in range(n):
        let scaled = eigenvalues[i] * 1000.0
        let rounded = floor(scaled + 0.5) if scaled >= 0.0 else ceil(scaled - 0.5)
        let bits = bitcast[UInt32](Int32(rounded))
        for byte in range(4): staged[4 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    for i in range(4 * n): output[i] = staged[i]
    return Int64(4 * n)
