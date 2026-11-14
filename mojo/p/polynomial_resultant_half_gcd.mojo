# Uncompiled and unexecuted Mojo half-GCD resultant draft.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime RP_MOD = Int64(998244353)

fn rp_power(value: Int64, exponent_value: Int) -> Int64:
    var x = value
    var n = exponent_value
    var answer: Int64 = 1
    while n > 0:
        if (n & 1) != 0: answer = (answer * x) % RP_MOD
        x = (x * x) % RP_MOD
        n >>= 1
    return answer

fn rp_trim(mut a: List[Int64]):
    while len(a) > 0 and a[len(a)-1] == 0:
        _ = a.pop()

fn rp_ntt(mut a: List[Int64], inverse: Bool):
    let n = len(a)
    var j = 0
    for i in range(1, n):
        var bit = n >> 1
        while (j & bit) != 0:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            let t = a[i]
            a[i] = a[j]
            a[j] = t
    var width = 2
    while width <= n:
        var root = rp_power(3, Int((RP_MOD-1) // Int64(width)))
        if inverse: root = rp_power(root, Int(RP_MOD-2))
        var start = 0
        while start < n:
            var factor: Int64 = 1
            for k in range(width // 2):
                let x = a[start+k]
                let y = (a[start+k+width//2] * factor) % RP_MOD
                a[start+k] = (x+y) % RP_MOD
                a[start+k+width//2] = (x-y+RP_MOD) % RP_MOD
                factor = (factor*root) % RP_MOD
            start += width
        width *= 2
    if inverse:
        let scale = rp_power(Int64(n), Int(RP_MOD-2))
        for i in range(n): a[i] = (a[i]*scale) % RP_MOD

fn rp_mul(a: List[Int64], b: List[Int64]) -> List[Int64]:
    if len(a) == 0 or len(b) == 0: return List[Int64]()
    let count = len(a)+len(b)-1
    var output = List[Int64](length=count, fill=0)
    if len(a) <= 32 or len(b) <= 32:
        for i in range(len(a)):
            for j in range(len(b)): output[i+j] = (output[i+j]+a[i]*b[j]) % RP_MOD
    else:
        var size = 1
        while size < count: size *= 2
        var left = List[Int64](length=size, fill=0)
        var right = List[Int64](length=size, fill=0)
        for i in range(len(a)): left[i] = a[i]
        for i in range(len(b)): right[i] = b[i]
        rp_ntt(left, False)
        rp_ntt(right, False)
        for i in range(size): left[i] = (left[i]*right[i]) % RP_MOD
        rp_ntt(left, True)
        for i in range(count): output[i] = left[i]
    rp_trim(output)
    return output^

fn rp_add(a: List[Int64], b: List[Int64]) -> List[Int64]:
    var size = len(a)
    if len(b) > size: size = len(b)
    var output = List[Int64](length=size, fill=0)
    for i in range(len(a)): output[i] = a[i]
    for i in range(len(b)): output[i] = (output[i]+b[i]) % RP_MOD
    rp_trim(output)
    return output^

fn rp_inverse(f: List[Int64], count: Int) -> List[Int64]:
    var inverse = List[Int64](length=1, fill=rp_power(f[0], Int(RP_MOD-2)))
    while len(inverse) < count:
        var size = 2*len(inverse)
        if size > count: size = count
        var prefix_len = len(f)
        if prefix_len > size: prefix_len = size
        var prefix = List[Int64](length=prefix_len, fill=0)
        for i in range(prefix_len): prefix[i] = f[i]
        let product = rp_mul(prefix, inverse)
        var correction = List[Int64](length=size, fill=0)
        for i in range(size):
            if i < len(product): correction[i] = (RP_MOD-product[i]) % RP_MOD
        correction[0] = (correction[0]+2) % RP_MOD
        let updated = rp_mul(inverse, correction)
        var next = List[Int64](length=size, fill=0)
        for i in range(len(updated)):
            if i < size: next[i] = updated[i]
        inverse = next^
    return inverse^

fn rp_divrem(a: List[Int64], b: List[Int64]) -> List[List[Int64]]:
    var pair = List[List[Int64]]()
    if len(a) < len(b):
        pair.append(List[Int64]())
        var remainder = List[Int64](length=len(a), fill=0)
        for i in range(len(a)): remainder[i] = a[i]
        pair.append(remainder^)
        return pair^
    let count = len(a)-len(b)+1
    var high = List[Int64](length=count, fill=0)
    var reversed = List[Int64](length=len(b), fill=0)
    for i in range(count): high[i] = a[len(a)-1-i]
    for i in range(len(b)): reversed[i] = b[len(b)-1-i]
    let inverse = rp_inverse(reversed, count)
    let reversed_q = rp_mul(high, inverse)
    var q = List[Int64](length=count, fill=0)
    for i in range(count):
        let j = count-1-i
        if j < len(reversed_q): q[i] = reversed_q[j]
    let removed = rp_mul(q, b)
    var r = List[Int64](length=len(b)-1, fill=0)
    for i in range(len(r)):
        var sub: Int64 = 0
        if i < len(removed): sub = removed[i]
        r[i] = (a[i]-sub+RP_MOD) % RP_MOD
    rp_trim(q)
    rp_trim(r)
    pair.append(q^)
    pair.append(r^)
    return pair^

fn rp_copy(a: List[Int64]) -> List[Int64]:
    var copy = List[Int64](length=len(a), fill=0)
    for i in range(len(a)): copy[i] = a[i]
    return copy^

fn rp_upper(a: List[Int64], shift: Int) -> List[Int64]:
    var result = List[Int64]()
    for i in range(shift, len(a)): result.append(a[i])
    return result^

# Matrix entries are row-major; the matrix acts on a column pair.
fn rp_identity() -> List[List[Int64]]:
    var matrix = List[List[Int64]]()
    var one = List[Int64]()
    one.append(1)
    matrix.append(rp_copy(one))
    matrix.append(List[Int64]())
    matrix.append(List[Int64]())
    matrix.append(one^)
    return matrix^

fn rp_step(q: List[Int64]) -> List[List[Int64]]:
    var matrix = List[List[Int64]]()
    var one = List[Int64]()
    one.append(1)
    var negative = List[Int64](length=len(q), fill=0)
    for i in range(len(q)): negative[i] = (RP_MOD-q[i]) % RP_MOD
    matrix.append(List[Int64]())
    matrix.append(rp_copy(one))
    matrix.append(one^)
    matrix.append(negative^)
    return matrix^

fn rp_dot(a: List[Int64], b: List[Int64], c: List[Int64], d: List[Int64]) -> List[Int64]:
    let left = rp_mul(a, b)
    let right = rp_mul(c, d)
    return rp_add(left, right)

fn rp_compose(x: List[List[Int64]], y: List[List[Int64]]) -> List[List[Int64]]:
    var matrix = List[List[Int64]]()
    matrix.append(rp_dot(x[0], y[0], x[1], y[2]))
    matrix.append(rp_dot(x[0], y[1], x[1], y[3]))
    matrix.append(rp_dot(x[2], y[0], x[3], y[2]))
    matrix.append(rp_dot(x[2], y[1], x[3], y[3]))
    return matrix^

fn rp_apply(m: List[List[Int64]], a: List[Int64], b: List[Int64]) -> List[List[Int64]]:
    var pair = List[List[Int64]]()
    pair.append(rp_dot(m[0], a, m[1], b))
    pair.append(rp_dot(m[2], a, m[3], b))
    return pair^

fn rp_half(a: List[Int64], b: List[Int64], mut degrees: List[Int64],
           mut leading: List[Int64]) -> List[List[Int64]]:
    if len(b) == 0: return rp_identity()
    let degree = len(a)-1
    let threshold = (degree+1) // 2
    if len(b) <= threshold: return rp_identity()
    if degree <= 64:
        var x = rp_copy(a)
        var y = rp_copy(b)
        var matrix = rp_identity()
        while len(y) > threshold and len(y) > 0:
            let division = rp_divrem(x, y)
            degrees.append(Int64(len(division[0])-1))
            leading.append(division[0][len(division[0])-1])
            let single = rp_step(division[0])
            matrix = rp_compose(single, matrix)
            x = rp_copy(y)
            y = rp_copy(division[1])
        return matrix^
    let high_a = rp_upper(a, threshold)
    let high_b = rp_upper(b, threshold)
    var first = rp_half(high_a, high_b, degrees, leading)
    let reduced = rp_apply(first, a, b)
    if len(reduced[1]) == 0 or len(reduced[1]) <= threshold: return first^
    let division = rp_divrem(reduced[0], reduced[1])
    degrees.append(Int64(len(division[0])-1))
    leading.append(division[0][len(division[0])-1])
    let single = rp_step(division[0])
    var prefix = rp_compose(single, first)
    if len(division[1]) == 0: return prefix^
    let shift = 2*threshold-(len(reduced[1])-1)
    if shift >= len(division[1]): return prefix^
    let upper_a = rp_upper(reduced[1], shift)
    let upper_b = rp_upper(division[1], shift)
    let last = rp_half(upper_a, upper_b, degrees, leading)
    return rp_compose(last, prefix)

fn rp_resultant(first: List[Int64], second: List[Int64]) -> Int64:
    var a = rp_copy(first)
    var b = rp_copy(second)
    var answer: Int64 = 1
    if len(a) < len(b):
        if ((len(a)-1) & 1) != 0 and ((len(b)-1) & 1) != 0: answer = RP_MOD-answer
        var temporary = a^
        a = b^
        b = temporary^
    while True:
        if len(b) == 1: return (answer*rp_power(b[0], len(a)-1)) % RP_MOD
        var degrees = List[Int64]()
        var leading = List[Int64]()
        var reduced = List[List[Int64]]()
        if len(a) != len(b):
            let matrix = rp_half(a, b, degrees, leading)
            if len(degrees) > 0: reduced = rp_apply(matrix, a, b)
        if len(degrees) == 0:
            let division = rp_divrem(a, b)
            if len(division[1]) == 0: return 0
            let da = len(a)-1
            let db = len(b)-1
            let dr = len(division[1])-1
            if (da & 1) != 0 and (db & 1) != 0: answer = RP_MOD-answer
            answer = (answer*rp_power(b[len(b)-1], da-dr)) % RP_MOD
            a = rp_copy(b)
            b = rp_copy(division[1])
        else:
            if len(reduced[1]) == 0: return 0
            var da = len(a)-1
            var db = len(b)-1
            var lead = b[len(b)-1]
            for i in range(len(degrees)):
                let last = i+1 == len(degrees)
                var dr = len(reduced[1])-1
                if not last: dr = db-Int(degrees[i+1])
                if (da & 1) != 0 and (db & 1) != 0: answer = RP_MOD-answer
                answer = (answer*rp_power(lead, da-dr)) % RP_MOD
                if not last: lead = (lead*rp_power(leading[i+1], Int(RP_MOD-2))) % RP_MOD
                da = db
                db = dr
            a = rp_copy(reduced[0])
            b = rp_copy(reduced[1])
    return answer

@export("polynomial_resultant_half_gcd")
fn polynomial_resultant_half_gcd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 100002: return -1
    let m = input[0]
    let n = input[1]
    if m < 0 or m > 50000 or n < 0 or n > 50000 or m+n > 99998: return -1
    let first_count = Int(m)+1
    let second_count = Int(n)+1
    if length != c_size_t(first_count+second_count+2): return -1
    var a = List[Int64](length=first_count, fill=0)
    var b = List[Int64](length=second_count, fill=0)
    for i in range(first_count):
        a[i] = input[2+i]
        if a[i] < 0 or a[i] >= RP_MOD: return -1
    for i in range(second_count):
        b[i] = input[2+first_count+i]
        if b[i] < 0 or b[i] >= RP_MOD: return -1
    if a[len(a)-1] == 0 or b[len(b)-1] == 0: return -1
    return rp_resultant(a, b)
