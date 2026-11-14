from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn gs_choose(men: Int, women: Int, quota: Int, first: InlineArray[Int64, 4],
             second: InlineArray[Int64, 4], lower: InlineArray[Int64, 4],
             upper: InlineArray[Int64, 4], by_men: Bool) -> InlineArray[Int64, 4]:
    let edges = men * women
    var answer = InlineArray[Int64, 4](fill=0)
    var combinations = 1
    for _ in range(edges): combinations *= 3
    var best: Int64 = -1
    for code in range(combinations):
        var candidate = InlineArray[Int64, 4](fill=0)
        var digits = code
        var e = edges
        while e > 0:
            e -= 1
            candidate[e] = Int64(digits % 3)
            digits //= 3
        var feasible = True
        for edge in range(edges):
            if candidate[edge] < lower[edge] or candidate[edge] > upper[edge]: feasible = False
        if by_men:
            for m in range(men):
                var total: Int64 = 0
                for w in range(women): total += candidate[m * women + w]
                if total > Int64(quota): feasible = False
        else:
            for w in range(women):
                var total: Int64 = 0
                for m in range(men): total += candidate[m * women + w]
                if total > Int64(quota): feasible = False
        if feasible:
            var value: Int64 = 0
            for edge in range(edges):
                if candidate[edge] >= 1: value += first[edge]
                if candidate[edge] >= 2: value += second[edge]
            if value > best:
                best = value
                answer = candidate
    return answer

@export("extended_gs_general_stable_allocation")
fn extended_gs_general_stable_allocation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 19: return -1
    if input[0] < 1 or input[0] > 2 or input[1] < 1 or input[1] > 2 or input[2] < 1 or input[2] > 2: return -1
    let men = Int(input[0])
    let women = Int(input[1])
    let quota = Int(input[2])
    let edges = men * women
    if Int(length) != 3 + 4 * edges: return -1
    var mf = InlineArray[Int64, 4](fill=0)
    var ms = InlineArray[Int64, 4](fill=0)
    var wf = InlineArray[Int64, 4](fill=0)
    var ws = InlineArray[Int64, 4](fill=0)
    for edge in range(edges):
        mf[edge] = input[3 + 4 * edge]
        ms[edge] = input[4 + 4 * edge]
        wf[edge] = input[5 + 4 * edge]
        ws[edge] = input[6 + 4 * edge]
        if mf[edge] < 0 or mf[edge] > 8 or ms[edge] < 0 or ms[edge] > mf[edge] or wf[edge] < 0 or wf[edge] > 8 or ws[edge] < 0 or ws[edge] > wf[edge]: return -1
    var xw = InlineArray[Int64, 4](fill=0)
    var zw = InlineArray[Int64, 4](fill=0)
    var xm = InlineArray[Int64, 4](fill=0)
    var zm = InlineArray[Int64, 4](fill=255)
    let zero = InlineArray[Int64, 4](fill=0)
    var converged = False
    for _ in range(3 * edges + 2):
        xm = gs_choose(men, women, quota, mf, ms, xw, zm, True)
        let next = gs_choose(men, women, quota, wf, ws, zero, xm, False)
        converged = True
        for edge in range(edges):
            if xm[edge] != next[edge]: converged = False
        if converged: break
        for edge in range(edges):
            if xm[edge] > next[edge]:
                zm[edge] = next[edge]
                zw[edge] = 255
            xw[edge] = next[edge]
    if not converged: return -1
    let size = 8 * (1 + 3 * edges)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(size): return -2
    for i in range(1 + 3 * edges):
        var value: Int64 = 0
        if i == 0: value = Int64(edges)
        elif i <= edges: value = xm[i - 1]
        elif i <= 2 * edges: value = zm[i - 1 - edges]
        else:
            let edge = i - 1 - 2 * edges
            value = xm[edge]
            if zw[edge] > value: value = zw[edge]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(size)
