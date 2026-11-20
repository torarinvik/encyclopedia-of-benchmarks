from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sch_lit_var(literal: Int64) -> Int:
    return Int(literal if literal > 0 else -literal) - 1

fn sch_lit_true(literal: Int64, value: Int) -> Bool:
    if literal > 0: return value == 1
    return value == 0

fn sch_prefix_size(m: Int) -> Int:
    var count = m
    var bits = 0
    while count > 0:
        bits += 1
        count = count >> 1
    return bits + 1

fn sch_ppz(formula: InlineArray[Int64, 24], lengths: InlineArray[Int, 4],
           n: Int, m: Int, fixed: InlineArray[Int, 6],
           permutation: InlineArray[Int, 6], random_bits: InlineArray[Int, 6],
           inout stats: InlineArray[Int64, 4], inout local: InlineArray[Int, 6]) -> Bool:
    var active = InlineArray[Int, 6]()
    var active_count = 0
    for v in range(6): local[v] = -1
    for position in range(n):
        let v = permutation[position] - 1
        if fixed[v] < 0:
            active[active_count] = v
            active_count += 1
    var work = formula
    var work_lengths = lengths
    var work_m = m
    for offset in range(active_count):
        let v = active[offset]
        var positive = False
        var negative = False
        for c in range(work_m):
            if work_lengths[c] == 1:
                let literal = work[c * 6]
                if literal == Int64(v + 1): positive = True
                if literal == -Int64(v + 1): negative = True
        var value = 0
        if positive:
            value = 1
            stats[1] += 1
        elif negative:
            value = 0
            stats[1] += 1
        else:
            value = random_bits[offset]
            stats[2] += 1
        local[v] = value
        var next = InlineArray[Int64, 24]()
        var next_lengths = InlineArray[Int, 4]()
        var next_m = 0
        for c in range(work_m):
            var satisfied = False
            var kept = 0
            for j in range(work_lengths[c]):
                let literal = work[c * 6 + j]
                if sch_lit_var(literal) != v:
                    next[next_m * 6 + kept] = literal
                    kept += 1
                elif sch_lit_true(literal, value):
                    satisfied = True
                    break
            if not satisfied:
                next_lengths[next_m] = kept
                next_m += 1
        work = next
        work_lengths = next_lengths
        work_m = next_m
    for c in range(work_m):
        if work_lengths[c] == 0: return False
    return True

fn sch_restrict(formula: InlineArray[Int64, 24], lengths: InlineArray[Int, 4],
                m: Int, fixed: InlineArray[Int, 6],
                inout next: InlineArray[Int64, 24],
                inout next_lengths: InlineArray[Int, 4]) -> Int:
    var next_m = 0
    for c in range(m):
        var satisfied = False
        var kept = 0
        for j in range(lengths[c]):
            let literal = formula[c * 6 + j]
            let value = fixed[sch_lit_var(literal)]
            if value < 0:
                next[next_m * 6 + kept] = literal
                kept += 1
            elif sch_lit_true(literal, value):
                satisfied = True
                break
        if not satisfied:
            next_lengths[next_m] = kept
            next_m += 1
    return next_m

fn sch_put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[word * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("schuler_randomized_general_cnf_sat")
fn schuler_randomized_general_cnf_sat(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 122: return -1
    let n0 = input[0]
    let m0 = input[1]
    if n0 < 1 or n0 > 6 or m0 < 1 or m0 > 4: return -1
    let n = Int(n0)
    let clauses = Int(m0)
    var formula = InlineArray[Int64, 24]()
    var lengths = InlineArray[Int, 4]()
    var at = 2
    for c in range(clauses):
        if at >= Int(length): return -1
        let count64 = input[at]
        at += 1
        if count64 < 1 or count64 > n0 or at + Int(count64) > Int(length): return -1
        let count = Int(count64)
        var seen = InlineArray[Bool, 6](fill=False)
        lengths[c] = count
        for j in range(count):
            let literal = input[at]
            at += 1
            if literal == 0 or literal < -n0 or literal > n0: return -1
            let v = sch_lit_var(literal)
            if seen[v]: return -1
            seen[v] = True
            formula[c * 6 + j] = literal

    var permutations = InlineArray[Int, 42]()
    var random_bits = InlineArray[Int, 42]()
    var choices = InlineArray[Int, 7]()
    for call in range(n + 1):
        var seen = InlineArray[Bool, 6](fill=False)
        for j in range(n):
            if at >= Int(length): return -1
            let v = input[at]
            at += 1
            if v < 1 or v > n0 or seen[Int(v) - 1]: return -1
            seen[Int(v) - 1] = True
            permutations[call * 6 + j] = Int(v)
        for j in range(n):
            if at >= Int(length) or (input[at] != 0 and input[at] != 1): return -1
            random_bits[call * 6 + j] = Int(input[at])
            at += 1
        if at >= Int(length): return -1
        let choice = input[at]
        at += 1
        if choice < 0 or choice >= m0: return -1
        choices[call] = Int(choice)
    if at != Int(length): return -1

    var fixed = InlineArray[Int, 6](fill=-1)
    var current = formula
    var current_lengths = lengths
    var current_m = clauses
    var stats = InlineArray[Int64, 4](fill=0)
    var found = False
    var mask: Int64 = 0
    var depth = 0
    while True:
        stats[0] += 1
        if Int64(depth) > stats[3]: stats[3] = Int64(depth)
        if current_m == 0:
            found = True
            for v in range(n):
                if fixed[v] == 1: mask |= Int64(1) << UInt(v)
            break
        let k = sch_prefix_size(current_m)
        var shortened = InlineArray[Int64, 24]()
        var short_lengths = InlineArray[Int, 4]()
        for c in range(current_m):
            short_lengths[c] = min(current_lengths[c], k)
            for j in range(short_lengths[c]): shortened[c * 6 + j] = current[c * 6 + j]
        var local = InlineArray[Int, 6](fill=-1)
        var permutation = InlineArray[Int, 6]()
        var call_bits = InlineArray[Int, 6]()
        for j in range(n):
            permutation[j] = permutations[depth * 6 + j]
            call_bits[j] = random_bits[depth * 6 + j]
        if sch_ppz(shortened, short_lengths, n, current_m, fixed, permutation, call_bits, stats, local):
            found = True
            for v in range(n):
                if fixed[v] == 1 or (fixed[v] < 0 and local[v] == 1): mask |= Int64(1) << UInt(v)
            break
        var eligible = InlineArray[Int, 4]()
        var eligible_count = 0
        for c in range(current_m):
            if short_lengths[c] == k:
                eligible[eligible_count] = c
                eligible_count += 1
        if eligible_count == 0: break
        if choices[depth] >= eligible_count: return -1
        let selected = eligible[choices[depth]]
        var next_fixed = fixed
        for j in range(k):
            let literal = shortened[selected * 6 + j]
            next_fixed[sch_lit_var(literal)] = 0 if literal > 0 else 1
        var next = InlineArray[Int64, 24]()
        var next_lengths = InlineArray[Int, 4]()
        current_m = sch_restrict(current, current_lengths, current_m, next_fixed, next, next_lengths)
        current = next
        current_lengths = next_lengths
        fixed = next_fixed
        depth += 1
        if depth > n: return -1
    if not found: mask = 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 48: return -2
    var staged = InlineArray[Int64, 6]()
    staged[0] = 1 if found else 0
    staged[1] = mask
    staged[2] = stats[0]
    staged[3] = stats[1]
    staged[4] = stats[2]
    staged[5] = stats[3]
    for word in range(6): sch_put_i64(output, word, staged[word])
    return 48
