from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn wm_less(prefix: List[Int], zeros: List[Int], first: Int, last: Int, key: Int) -> Int:
    var left = first
    var right = last
    var result = 0
    for level in range(11):
        let zl = prefix[level*65+left]
        let zr = prefix[level*65+right]
        if key & (1 << (10-level)) != 0:
            result += zr-zl
            left = zeros[level]+left-zl
            right = zeros[level]+right-zr
        else:
            left = zl
            right = zr
    return result

fn wm_quantile(prefix: List[Int], zeros: List[Int], first: Int, last: Int, rank: Int) -> Int:
    var left = first
    var right = last
    var k = rank
    var key = 0
    for level in range(11):
        let zl = prefix[level*65+left]
        let zr = prefix[level*65+right]
        if k < zr-zl:
            left = zl
            right = zr
        else:
            k -= zr-zl
            key |= 1 << (10-level)
            left = zeros[level]+left-zl
            right = zeros[level]+right-zr
    return key-1000

@export("wavelet_matrix")
fn wavelet_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 706: return -1
    let nv = input[0]
    if nv < 1 or nv > 64: return -1
    let n = Int(nv)
    if length < c_size_t(n+2): return -1
    for i in range(n):
        if input[1+i] < -1000 or input[1+i] > 1000: return -1
    let qv = input[n+1]
    if qv < 0 or qv > 128 or length != c_size_t(n+2+5*Int(qv)): return -1
    var prefix = List[Int](capacity=715)
    var zeros = List[Int](capacity=11)
    var current = List[Int](capacity=64)
    var scratch = List[Int](capacity=64)
    for _ in range(715): prefix.append(0)
    for _ in range(11): zeros.append(0)
    for _ in range(64):
        current.append(0)
        scratch.append(0)
    for i in range(n): current[i] = Int(input[1+i])+1000
    for level in range(11):
        let bit = 10-level
        for i in range(n):
            var count = prefix[level*65+i]
            if current[i] & (1 << bit) == 0: count += 1
            prefix[level*65+i+1] = count
        var z = 0
        var o = prefix[level*65+n]
        zeros[level] = o
        for i in range(n):
            if current[i] & (1 << bit) == 0:
                scratch[z] = current[i]
                z += 1
            else:
                scratch[o] = current[i]
                o += 1
        for i in range(n): current[i] = scratch[i]
    var total: Int64 = 0
    for j in range(Int(qv)):
        let at = n+2+5*j
        let op = input[at]
        let a = input[at+1]
        let b = input[at+2]
        let c = input[at+3]
        let d = input[at+4]
        var answer = 0
        if op == 0:
            if a < -1000 or a > 1000 or b < -1 or b >= nv: return -1
            answer = wm_less(prefix, zeros, 0, Int(b)+1, Int(a)+1001)-wm_less(prefix, zeros, 0, Int(b)+1, Int(a)+1000)
        elif op == 1:
            if a < 0 or a > b or b >= nv or c < 0 or c > b-a: return -1
            answer = wm_quantile(prefix, zeros, Int(a), Int(b)+1, Int(c))
        elif op == 2:
            if a < 0 or a > b or b >= nv or c < -1000 or c > d or d > 1000: return -1
            answer = wm_less(prefix, zeros, Int(a), Int(b)+1, Int(d)+1001)-wm_less(prefix, zeros, Int(a), Int(b)+1, Int(c)+1000)
        else: return -1
        total += Int64(j+1)*Int64(answer+1000001)
    return total
