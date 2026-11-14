# Uncompiled bounded GF(2) quadratic normal-form draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@fieldwise_init
struct QfVec(Copyable):
    var lo: UInt64
    var hi: UInt64

fn qf_xor(a: QfVec, b: QfVec) -> QfVec:
    return QfVec(a.lo ^ b.lo, a.hi ^ b.hi)

fn qf_bit(v: QfVec, i: Int) -> Bool:
    if i < 64: return ((v.lo >> i) & 1) != 0
    return ((v.hi >> (i - 64)) & 1) != 0

fn qf_set(inout v: QfVec, i: Int):
    if i < 64: v.lo |= UInt64(1) << i
    else: v.hi |= UInt64(1) << (i - 64)

fn qf_parity(value: UInt64) -> Int:
    var x = value
    x ^= x >> 32; x ^= x >> 16; x ^= x >> 8
    x ^= x >> 4; x ^= x >> 2; x ^= x >> 1
    return Int(x & 1)

fn qf_apply(rows: InlineArray[QfVec, 100], n: Int, a: QfVec, b: QfVec) -> Int:
    var result = 0
    for i in range(n):
        if qf_bit(a, i): result ^= qf_parity((rows[i].lo & b.lo) ^ (rows[i].hi & b.hi))
    return result

@export("quadratic_form_gf2_normal_form")
fn quadratic_form_gf2_normal_form(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 202: return -1
    if input[0] < 1 or input[0] > 100: return -1
    let n = Int(input[0])
    let words = (n + 62) // 63
    if length != c_size_t(1 + n * words): return -1
    var upper = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    var bilinear = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    for i in range(n):
        for chunk in range(words):
            let raw = input[1 + i * words + chunk]
            if raw < 0: return -1
            for b in range(63):
                if ((UInt64(raw) >> b) & 1) == 0: continue
                let j = 63 * chunk + b
                if j >= n or j < i: return -1
                qf_set(upper[i], j)
                if i != j:
                    qf_set(bilinear[i], j)
                    qf_set(bilinear[j], i)
    let row_bytes = (n + 7) // 8
    let needed = 3 + n * row_bytes
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var remaining = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    var hyper = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    var anis = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    var columns = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    for i in range(n): qf_set(remaining[i], i)
    var count = n
    var hc = 0
    var ac = 0
    while True:
        var left = count
        var right = count
        for i in range(count):
            for j in range(i + 1, count):
                if qf_apply(bilinear, n, remaining[i], remaining[j]) != 0:
                    left = i; right = j; break
            if left != count: break
        if left == count: break
        var u = remaining[left]
        var v = remaining[right]
        var rest = InlineArray[QfVec, 100](fill=QfVec(0, 0))
        var next = 0
        for i in range(count):
            if i == left or i == right: continue
            var w = remaining[i]
            if qf_apply(bilinear, n, remaining[i], v) != 0: w = qf_xor(w, u)
            if qf_apply(bilinear, n, remaining[i], u) != 0: w = qf_xor(w, v)
            rest[next] = w; next += 1
        remaining = rest; count = next
        let qu = qf_apply(upper, n, u, u)
        let qv = qf_apply(upper, n, v, v)
        if qu != 0 and qv != 0:
            anis[ac] = u; anis[ac + 1] = v; ac += 2
        else:
            if qu != 0: u = qf_xor(u, v)
            elif qv != 0: v = qf_xor(v, u)
            hyper[hc] = u; hyper[hc + 1] = v; hc += 2
    while ac >= 4:
        let a = anis[ac - 2]; let b = anis[ac - 1]
        let c = anis[ac - 4]; let d = anis[ac - 3]
        ac -= 4
        let f = qf_xor(d, qf_xor(a, b))
        hyper[hc] = qf_xor(a, c); hyper[hc + 1] = qf_xor(b, c)
        hyper[hc + 2] = f; hyper[hc + 3] = qf_xor(f, c); hc += 4
    var linear = QfVec(0, 0)
    var has_linear = False
    for i in range(count):
        if qf_apply(upper, n, remaining[i], remaining[i]) == 0: continue
        linear = remaining[i]; has_linear = True
        for j in range(i + 1, count): remaining[j - 1] = remaining[j]
        count -= 1; break
    if has_linear:
        for i in range(count):
            if qf_apply(upper, n, remaining[i], remaining[i]) != 0:
                remaining[i] = qf_xor(remaining[i], linear)
        if ac != 0:
            hyper[hc] = qf_xor(anis[0], linear); hyper[hc + 1] = qf_xor(anis[1], linear)
            hc += 2; ac = 0
    var used = 0
    for i in range(hc): columns[used] = hyper[i]; used += 1
    for i in range(ac): columns[used] = anis[i]; used += 1
    if has_linear: columns[used] = linear; used += 1
    for i in range(count): columns[used] = remaining[i]; used += 1
    if used != n or hc % 2 != 0 or (ac != 0 and ac != 2): return -4
    var matrix = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    var inverse = InlineArray[QfVec, 100](fill=QfVec(0, 0))
    for i in range(n):
        qf_set(inverse[i], i)
        for j in range(n):
            if qf_bit(columns[j], i): qf_set(matrix[i], j)
    for col in range(n):
        var pivot = col
        while pivot < n and not qf_bit(matrix[pivot], col): pivot += 1
        if pivot == n: return -4
        let temp = matrix[col]; matrix[col] = matrix[pivot]; matrix[pivot] = temp
        let inv_temp = inverse[col]; inverse[col] = inverse[pivot]; inverse[pivot] = inv_temp
        for row in range(n):
            if row != col and qf_bit(matrix[row], col):
                matrix[row] = qf_xor(matrix[row], matrix[col])
                inverse[row] = qf_xor(inverse[row], inverse[col])
    var staged = InlineArray[UInt8, 1303](fill=0)
    staged[0] = UInt8(hc // 2); staged[1] = UInt8(ac // 2)
    if has_linear: staged[2] = 1
    for i in range(n):
        for j in range(n):
            if qf_bit(inverse[i], j):
                staged[3 + i * row_bytes + j // 8] |= UInt8(1 << (j % 8))
    for i in range(needed): output[i] = staged[i]
    return Int64(needed)
