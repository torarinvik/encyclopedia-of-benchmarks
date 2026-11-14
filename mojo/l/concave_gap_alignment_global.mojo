# Independent bounded global-alignment recurrence; see package provenance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("concave_gap_alignment_global")
fn concave_gap_alignment_global(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 26: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 8 or mv < 1 or mv > 8: return -1
    let n = Int(nv)
    let m = Int(mv)
    var gaps = n
    if m > n: gaps = m
    if length != c_size_t(2+n+m+gaps): return -1
    for i in range(n+m):
        if input[2+i] < 0 or input[2+i] > 3: return -1
    let base = 2+n+m
    var prior = Int64(0)
    var slope = Int64(101)
    for i in range(gaps):
        let value = input[base+i]
        if value < 0 or value > 100: return -1
        let increment = value - prior
        if increment < 0 or increment > slope: return -1
        prior = value
        slope = increment
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var dp = List[Int64](capacity=81)
    for _ in range(81): dp.append(1000000)
    dp[0] = 0
    for i in range(n+1):
        for j in range(m+1):
            if i == 0 and j == 0: continue
            var best = Int64(1000000)
            if i > 0 and j > 0:
                var mismatch = Int64(0)
                if input[2+i-1] != input[2+n+j-1]: mismatch = 1
                best = dp[9*(i-1)+j-1] + mismatch
            for k in range(1, i+1):
                let candidate = dp[9*(i-k)+j] + input[base+k-1]
                if candidate < best: best = candidate
            for k in range(1, j+1):
                let candidate = dp[9*i+j-k] + input[base+k-1]
                if candidate < best: best = candidate
            dp[9*i+j] = best
    let result = dp[9*n+m]
    for byte in range(8): output[byte] = UInt8((result >> (8*byte)) & 255)
    return 8
