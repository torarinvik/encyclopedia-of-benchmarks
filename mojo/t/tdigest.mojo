from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import asin, sin, isfinite

fn td_limit(compression: Float64, q: Float64) -> Float64:
    var p = q
    if p < 0.0: p = 0.0
    if p > 1.0: p = 1.0
    let k = compression / 6.283185307179586476925286766559 * asin(2.0 * p - 1.0) + 1.0
    let angle = k * 6.283185307179586476925286766559 / compression
    if angle >= 1.57079632679489661923: return 1.0
    if angle <= -1.57079632679489661923: return 0.0
    return (sin(angle) + 1.0) / 2.0

fn td_interp(x0: Float64, y0: Float64, x1: Float64, y1: Float64, x: Float64) -> Float64:
    if x1 <= x0: return y1
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0)

@export("tdigest")
fn tdigest(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 7 or length > 45: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let comp = input[0]; let ns0 = input[1]
    if comp < 10.0 or comp > 20.0 or Float64(Int64(comp)) != comp or ns0 < 1.0 or ns0 > 32.0 or Float64(Int64(ns0)) != ns0: return -1
    let ns = Int(ns0); let qi = 2 + ns
    if qi >= Int(length): return -1
    let nq0 = input[qi]
    if nq0 < 1.0 or nq0 > 4.0 or Float64(Int64(nq0)) != nq0: return -1
    let nq = Int(nq0); let qs = qi + 1; let ci = qs + nq
    if ci >= Int(length): return -1
    let ncdf0 = input[ci]
    if ncdf0 < 1.0 or ncdf0 > 4.0 or Float64(Int64(ncdf0)) != ncdf0: return -1
    let ncdf = Int(ncdf0); let cs = ci + 1
    if Int(length) != cs + ncdf or length > 44: return -1
    var sorted = InlineArray[Float64, 32](); var probs = InlineArray[Float64, 4](); var cvals = InlineArray[Float64, 4]()
    for i in range(ns):
        let x = input[2 + i]
        if x < -8.0 or x > 8.0 or Float64(Int64(x)) != x: return -1
        sorted[i] = x
    for i in range(nq):
        let q = input[qs + i]
        if q < 0.0 or q > 1.0 or (q * 4.0) != Float64(Int64(q * 4.0)): return -1
        probs[i] = q
    for i in range(ncdf):
        let x = input[cs + i]
        if x < -8.0 or x > 8.0 or Float64(Int64(x)) != x: return -1
        cvals[i] = x
    for i in range(1, ns):
        let x = sorted[i]; var j = i
        while j > 0 and sorted[j - 1] > x:
            sorted[j] = sorted[j - 1]; j -= 1
        sorted[j] = x
    let total = Float64(ns); let centroid_cap = 2 * (Int(comp) + 2)
    var means = InlineArray[Float64, 44](); var weights = InlineArray[Float64, 44]
    var last = 0; means[0] = sorted[0]; weights[0] = 1.0
    var closed = 0.0; var limit = total * td_limit(comp, 0.0)
    for i in range(1, ns):
        let projected = weights[last] + 1.0
        if closed + projected <= limit or last == centroid_cap - 1:
            weights[last] = projected
            means[last] += (sorted[i] - means[last]) / projected
        else:
            closed += weights[last]; limit = total * td_limit(comp, closed / total)
            last += 1; means[last] = sorted[i]; weights[last] = 1.0
    let count = last + 1; let minimum = sorted[0]; let maximum = sorted[ns - 1]
    var staged = InlineArray[Float64, 10](); staged[0] = Float64(nq)
    for qi2 in range(nq):
        let q = probs[qi2]; let index = q * total
        var result: Float64 = 0.0
        if count == 1: result = means[0]
        elif index <= 0.0: result = minimum
        elif index >= total: result = maximum
        else:
            var pv = minimum; var pi = 0.0; var ci2 = 0.0; var found = False
            for j in range(count):
                if j == 0: ci2 += weights[j] / 2.0
                else: ci2 += (weights[j - 1] + weights[j]) / 2.0
                if not found and index < ci2:
                    result = td_interp(pi, pv, ci2, means[j], index); found = True
                if not found: pv = means[j]; pi = ci2
            if not found: result = td_interp(pi, pv, total, maximum, index)
        staged[1 + qi2] = result
    staged[1 + nq] = Float64(ncdf)
    for qi2 in range(ncdf):
        let x = cvals[qi2]; var result: Float64 = 0.0
        if x < minimum: result = 0.0
        elif x > maximum: result = 1.0
        elif maximum <= minimum: result = 0.5
        else:
            var pv = minimum; var pi = 0.0; var ci2 = 0.0; var found = False
            for j in range(count):
                if j == 0: ci2 += weights[j] / 2.0
                else: ci2 += (weights[j - 1] + weights[j]) / 2.0
                if not found and x < means[j]:
                    result = td_interp(pv, pi, means[j], ci2, x) / total; found = True
                if not found: pv = means[j]; pi = ci2
            if not found: result = td_interp(pv, pi, maximum, total, x) / total
        staged[2 + nq + qi2] = result
    let outn = nq + ncdf + 2
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(outn): return -2
    for i in range(outn): output[i] = staged[i]
    return Int64(outn)
