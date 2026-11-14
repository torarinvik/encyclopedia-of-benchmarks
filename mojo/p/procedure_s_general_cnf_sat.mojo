# Independent bounded Procedure S profile; see the package RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sat_solve(literals: InlineArray[Int, 30], lengths: InlineArray[Int, 6], clauses: Int,
             n: Int, k: Int, fixed: Int, values: Int, depth: Int,
             inout stats: InlineArray[Int, 4]) -> Int:
    stats[0] += 1
    stats[1] += 1
    stats[3] = max(stats[3], depth)
    for code in range(1 << n):
        var model = 0
        for variable in range(n):
            if (code & (1 << (n - variable - 1))) != 0: model |= 1 << variable
        if ((model ^ values) & fixed) != 0: continue
        var all = True
        for clause in range(clauses):
            var satisfied = False
            for j in range(min(lengths[clause], k)):
                let lit = literals[clause * 5 + j]
                let variable = (lit if lit > 0 else -lit) - 1
                let bit = (model & (1 << variable)) != 0
                if (lit > 0 and bit) or (lit < 0 and not bit): satisfied = True
            if not satisfied: all = False
        if all: return model
    for branch in range(clauses):
        let prefix = min(lengths[branch], k)
        if prefix == 0: continue
        stats[2] += 1
        var next_fixed = fixed
        var next_values = values
        var conflict = False
        for j in range(prefix):
            let lit = literals[branch * 5 + j]
            let variable = (lit if lit > 0 else -lit) - 1
            let bit = 1 << variable
            let required = bit if lit < 0 else 0
            if (next_fixed & bit) != 0 and (next_values & bit) != required: conflict = True
            next_fixed |= bit
            next_values = (next_values & ~bit) | required
        if conflict or next_fixed == fixed: continue
        let newly_fixed = next_fixed & ~fixed
        var child_literals = InlineArray[Int, 30](fill=0)
        var child_lengths = InlineArray[Int, 6](fill=0)
        var child_count = 0
        for clause in range(clauses):
            let limit = min(lengths[clause], k) if clause < branch else lengths[clause]
            var satisfied = False
            var kept = 0
            for j in range(limit):
                let lit = literals[clause * 5 + j]
                let variable = (lit if lit > 0 else -lit) - 1
                let bit = 1 << variable
                if (newly_fixed & bit) != 0:
                    let truth = (next_values & bit) != 0
                    if (lit > 0 and truth) or (lit < 0 and not truth): satisfied = True
                else:
                    child_literals[child_count * 5 + kept] = lit
                    kept += 1
            if not satisfied:
                child_lengths[child_count] = kept
                child_count += 1
        let model = sat_solve(child_literals, child_lengths, child_count, n, k, next_fixed, next_values, depth + 1, stats)
        if model >= 0: return model
    return -1

@export("procedure_s_general_cnf_sat")
fn procedure_s_general_cnf_sat(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 39: return -1
    let raw_n = input[0]
    let raw_m = input[1]
    let raw_k = input[2]
    if raw_n < 1 or raw_n > 5 or raw_m < 0 or raw_m > 6 or raw_k < 1 or raw_k > raw_n: return -1
    let n = Int(raw_n)
    let clauses = Int(raw_m)
    let k = Int(raw_k)
    var literals = InlineArray[Int, 30](fill=0)
    var lengths = InlineArray[Int, 6](fill=0)
    var offset = 3
    for clause in range(clauses):
        if offset >= Int(length): return -1
        let raw_count = input[offset]
        offset += 1
        if raw_count < 1 or raw_count > raw_n or offset + Int(raw_count) > Int(length): return -1
        let count = Int(raw_count)
        lengths[clause] = count
        var seen = 0
        for j in range(count):
            let raw_lit = input[offset]
            offset += 1
            if raw_lit == 0 or raw_lit < -raw_n or raw_lit > raw_n: return -1
            let lit = Int(raw_lit)
            let bit = 1 << ((lit if lit > 0 else -lit) - 1)
            if (seen & bit) != 0: return -1
            seen |= bit
            literals[clause * 5 + j] = lit
    if offset != Int(length): return -1
    var stats = InlineArray[Int, 4](fill=0)
    let model = sat_solve(literals, lengths, clauses, n, k, 0, 0, 0, stats)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 48: return -2
    let words = InlineArray[Int, 6](1 if model >= 0 else 0, model if model >= 0 else 0,
                                    stats[0], stats[1], stats[2], stats[3])
    for i in range(6):
        let bits = UInt64(words[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 48
