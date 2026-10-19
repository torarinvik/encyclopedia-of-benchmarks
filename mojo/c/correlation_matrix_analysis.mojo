from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("correlation_matrix_analysis")
fn correlation_matrix_analysis(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 22 or input[0] != 4 or input[1] < 2 or input[1] > 5: return -1
    let p = input[1]
    if length != 2 + 4 * p: return -1
    for i in range(4 * p):
        if input[2 + i] < -1000 or input[2 + i] > 1000: return -1
    for col in range(p):
        let first = input[2 + col]
        var varying = False
        for row in range(1, 4):
            if input[2 + row * p + col] != first: varying = True
        if not varying: return -1
    let bytes = 32 * p * p + 48
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var means = InlineArray[Float64, 5](0.0)
    var corr = InlineArray[Float64, 25](0.0)
    var raw = InlineArray[Float64, 25](1.0)
    var bonf = InlineArray[Float64, 25](1.0)
    var fdr = InlineArray[Float64, 25](1.0)
    for col in range(p):
        for row in range(4): means[col] += Float64(input[2 + row * p + col])
        means[col] /= 4.0
    for i in range(p): corr[i * p + i] = 1.0
    var pair_i = InlineArray[Int64, 10](0)
    var pair_j = InlineArray[Int64, 10](0)
    var pair_p = InlineArray[Float64, 10](0.0)
    var pair_count: Int64 = 0
    for j in range(1, p):
        for i in range(j):
            var cross: Float64 = 0.0
            var sum_i: Float64 = 0.0
            var sum_j: Float64 = 0.0
            for row in range(4):
                let dx = Float64(input[2 + row * p + i]) - means[i]
                let dy = Float64(input[2 + row * p + j]) - means[j]
                cross += dx * dy
                sum_i += dx * dx
                sum_j += dy * dy
            let r = cross / sqrt(sum_i * sum_j)
            let pv = 1.0 - (r if r >= 0.0 else -r)
            corr[i * p + j] = r
            corr[j * p + i] = r
            raw[i * p + j] = pv
            raw[j * p + i] = pv
            pair_i[pair_count] = i
            pair_j[pair_count] = j
            pair_p[pair_count] = pv
            pair_count += 1
    for k in range(pair_count):
        let scaled = pair_p[k] * Float64(pair_count)
        let adjusted = 1.0 if scaled > 1.0 else scaled
        let i = pair_i[k]
        let j = pair_j[k]
        bonf[i * p + j] = adjusted
        bonf[j * p + i] = adjusted
    var order = InlineArray[Int64, 10](0)
    for k in range(pair_count): order[k] = k
    for k in range(1, pair_count):
        let value = order[k]
        var at = k
        while at > 0 and pair_p[order[at - 1]] > pair_p[value]:
            order[at] = order[at - 1]
            at -= 1
        order[at] = value
    var running: Float64 = 1.0
    var pos = pair_count
    while pos > 0:
        pos -= 1
        var adjusted = pair_p[order[pos]] * Float64(pair_count) / Float64(pos + 1)
        if adjusted > 1.0: adjusted = 1.0
        if adjusted < running: running = adjusted
        let k = order[pos]
        let i = pair_i[k]
        let j = pair_j[k]
        fdr[i * p + j] = running
        fdr[j * p + i] = running
    var sig_raw: Int64 = 0
    var sig_bonf: Int64 = 0
    var sig_fdr: Int64 = 0
    for k in range(pair_count):
        let i = pair_i[k]
        let j = pair_j[k]
        if pair_p[k] < 0.05: sig_raw += 1
        if bonf[i * p + j] < 0.05: sig_bonf += 1
        if fdr[i * p + j] < 0.05: sig_fdr += 1
    var offset: Int64 = 0
    for matrix_id in range(4):
        for i in range(p * p):
            var value: Float64 = corr[i]
            if matrix_id == 1: value = raw[i]
            elif matrix_id == 2: value = bonf[i]
            elif matrix_id == 3: value = fdr[i]
            let bits = bitcast[UInt64](value)
            for b in range(8): output[offset + b] = UInt8((bits >> (8 * b)) & 255)
            offset += 8
    var summary = InlineArray[Int64, 6](0)
    summary[0] = 4
    summary[1] = p
    summary[2] = 0
    summary[3] = sig_raw
    summary[4] = sig_bonf
    summary[5] = sig_fdr
    for i in range(6):
        let bits = UInt64(summary[i])
        for b in range(8): output[offset + b] = UInt8((bits >> (8 * b)) & 255)
        offset += 8
    return offset
