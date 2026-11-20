from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("galil_seiferas_search")
fn galil_seiferas_search(a: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 162: return -2
    let raw_n = a[0]
    let raw_m = a[1]
    if raw_n < 0 or raw_n > 128 or raw_m < 1 or raw_m > 32 or length != c_size_t(2 + raw_n + raw_m): return -2
    let n = Int(raw_n)
    let m = Int(raw_m)
    for i in range(n + m):
        if a[2 + i] < 0 or a[2 + i] > 15: return -2
    if m > n: return 0
    let text_start = 2
    let pattern_start = 2 + n

    var s = 0
    var p1 = 1
    var q1 = 0
    var factorized = False
    while True:
        while s + p1 + q1 < m and a[pattern_start + s + q1] == a[pattern_start + s + p1 + q1]: q1 += 1
        if p1 + q1 >= 4 * p1:
            var p2 = q1
            var q2 = 0
            while True:
                while p2 + q2 < 4 * p2 and s + p2 + q2 < m and a[pattern_start + s + q2] == a[pattern_start + s + p2 + q2]:
                    q2 += 1
                if p2 + q2 == 4 * p2:
                    while True:
                        while s + p1 + q1 < m and a[pattern_start + s + q1] == a[pattern_start + s + p1 + q1]: q1 += 1
                        while p1 + q1 >= 4 * p1:
                            s += p1
                            q1 -= p1
                        if s + p1 + q1 == m: break
                        p1 += q1 // 4 + 1
                        q1 = 0
                        if p1 >= p2: break
                    break
                if s + p2 + q2 == m:
                    factorized = True
                    break
                if q2 == p1 + q1:
                    p2 += p1
                    q2 -= p1
                else:
                    p2 += q2 // 4 + 1
                    q2 = 0
            if factorized or s + p1 + q1 == m: break
        else:
            if s + p1 + q1 == m: break
            p1 += q1 // 4 + 1
            q1 = 0

    var p = 0
    var q = 0
    var matches = 0
    while p <= n - m:
        while s + q < m and a[pattern_start + s + q] == a[text_start + p + s + q]: q += 1
        if q == m - s:
            var i = 0
            while i < s and a[pattern_start + i] == a[text_start + p + i]: i += 1
            if i == s: matches += 1
        if q == p1 + q1:
            p += p1
            q -= p1
        else:
            p += q // 4 + 1
            q = 0
    return matches
