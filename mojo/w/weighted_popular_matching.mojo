from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn wpm_decode(encoded: Int, n: Int, m: Int, inout assignment: InlineArray[Int, 4]) -> Bool:
    var value = encoded
    var used = 0
    for i in range(n):
        let digit = value % (m + 1)
        value //= m + 1
        assignment[i] = digit - 1
        if digit > 0:
            let bit = 1 << (digit - 1)
            if used & bit != 0: return False
            used |= bit
    return True

@export("weighted_popular_matching")
fn weighted_popular_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 22: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 4 or mv < 1 or mv > 4: return -1
    let n = Int(nv)
    let m = Int(mv)
    if length != c_size_t(2 + n + n * m): return -1
    for i in range(n):
        if input[2 + i] < 1 or input[2 + i] > 1000: return -1
        var seen = 0
        for j in range(m):
            let rank = input[2 + n + i * m + j]
            if rank < 0 or rank >= mv: return -1
            let bit = 1 << Int(rank)
            if seen & bit != 0: return -1
            seen |= bit
    var possibilities = 1
    for _ in range(n): possibilities *= m + 1
    var best = InlineArray[Int, 4](fill=-1)
    var best_cardinality = -1
    for code in range(possibilities):
        var candidate = InlineArray[Int, 4](fill=-1)
        if not wpm_decode(code, n, m, candidate): continue
        var popular = True
        for alternate_code in range(possibilities):
            var alternate = InlineArray[Int, 4](fill=-1)
            if not wpm_decode(alternate_code, n, m, alternate): continue
            var margin: Int64 = 0
            for i in range(n):
                var current_rank = m
                var other_rank = m
                if candidate[i] >= 0: current_rank = Int(input[2 + n + i * m + candidate[i]])
                if alternate[i] >= 0: other_rank = Int(input[2 + n + i * m + alternate[i]])
                if other_rank < current_rank: margin += input[2 + i]
                elif other_rank > current_rank: margin -= input[2 + i]
            if margin > 0:
                popular = False
                break
        if popular:
            var cardinality = 0
            for i in range(n):
                if candidate[i] >= 0: cardinality += 1
            var smaller = False
            for i in range(n):
                if candidate[i] != best[i]:
                    smaller = candidate[i] < best[i]
                    break
            if cardinality > best_cardinality or (cardinality == best_cardinality and smaller):
                best_cardinality = cardinality
                for i in range(n): best[i] = candidate[i]
    let bytes = 8 * (n + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(n + 2):
        var value: Int64 = -1
        if word == 0: value = 1 if best_cardinality >= 0 else 0
        elif word == 1: value = Int64(best_cardinality) if best_cardinality >= 0 else 0
        elif best_cardinality >= 0: value = Int64(best[word - 2])
        let bits = bitcast[UInt64](value)
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
