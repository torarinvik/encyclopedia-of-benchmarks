from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn kopt_satisfied(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int, assignment: Int) -> UInt64:
    var satisfied: UInt64 = 0
    for clause in range(m):
        for j in range(3):
            let literal = input[2 + 3 * clause + j]
            let variable = Int(abs(literal)) - 1
            let truth = (assignment & (1 << (n - 1 - variable))) != 0
            if truth == (literal > 0):
                satisfied |= UInt64(1) << clause
                break
    return satisfied

@export("random_planted_3sat_k_opt")
fn random_planted_3sat_k_opt(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    if input[0] < 3 or input[0] > 12 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if Int(length) != 2 + 3 * m: return -1
    var positive = InlineArray[Int, 12](fill=0)
    var negative = InlineArray[Int, 12](fill=0)
    for clause in range(m):
        var seen = InlineArray[Bool, 12](fill=False)
        for j in range(3):
            let literal = input[2 + 3 * clause + j]
            if literal == 0 or literal < -Int64(n) or literal > Int64(n): return -1
            let variable = Int(abs(literal)) - 1
            if seen[variable]: return -1
            seen[variable] = True
            if literal > 0: positive[variable] += 1
            else: negative[variable] += 1
    var current = 0
    for variable in range(n):
        if positive[variable] > negative[variable]: current |= 1 << (n - 1 - variable)
    let full = (UInt64(1) << m) - UInt64(1)
    var k = 1
    var status: Int64 = 0
    while True:
        let before = kopt_satisfied(input, n, m, current)
        if before == full:
            status = 1
            break
        var found = False
        for candidate in range(1 << n):
            var difference = current ^ candidate
            var distance = 0
            while difference != 0:
                distance += difference & 1
                difference >>= 1
            if distance == 0 or distance > k: continue
            let after = kopt_satisfied(input, n, m, candidate)
            if after != before and (after & before) == before:
                current = candidate
                found = True
                break
        if found: continue
        if k == n: break
        k += 1
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(n + 1):
        var value = status
        if word > 0:
            value = if (current & (1 << (n - word))) != 0: 1 else: -1
        var bits = bitcast[UInt64](value)
        for b in range(8):
            output[8 * word + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
