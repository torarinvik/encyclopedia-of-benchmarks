# Bounded Hajiaghayi-Sorkin Algorithm A trace, without backtracking.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("random_3sat_hajiaghayi_sorkin_algorithm_a")
fn random_3sat_hajiaghayi_sorkin_algorithm_a(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 3 or nv > 12 or mv < 0 or mv > 32 or length != c_size_t(2 + 3 * mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var clauses = List[Int](capacity=3*m)
    var sizes = List[Int](capacity=m)
    var active = List[Bool](capacity=m)
    for c in range(m):
        var seen = 0
        for j in range(3):
            let raw = input[2 + 3*c + j]
            if raw == 0 or raw < -nv or raw > nv: return -1
            let variable = Int(raw if raw > 0 else -raw) - 1
            if (seen & (1 << variable)) != 0: return -1
            seen |= 1 << variable
            clauses.append(Int(raw))
        sizes.append(3)
        active.append(True)

    var assigned = List[Int](capacity=n)
    for _ in range(n): assigned.append(0)
    var assigned_count = 0
    var failed = False
    while assigned_count < n and not failed:
        var positive = List[Int](capacity=n)
        var negative = List[Int](capacity=n)
        for _ in range(n):
            positive.append(0)
            negative.append(0)
        for c in range(m):
            if not active[c]: continue
            for j in range(sizes[c]):
                let literal = clauses[3*c+j]
                let variable = (literal if literal > 0 else -literal) - 1
                if literal > 0: positive[variable] += 1
                else: negative[variable] += 1

        var selected = -1
        for variable in range(n):
            if assigned[variable] == 0 and (positive[variable] == 0 or negative[variable] == 0):
                selected = variable
                break
        if selected < 0:
            var best_difference = -1
            var best_total = -1
            for variable in range(n):
                if assigned[variable] != 0: continue
                let difference = Int((positive[variable] - negative[variable])
                    if positive[variable] > negative[variable]
                    else (negative[variable] - positive[variable]))
                let total = positive[variable] + negative[variable]
                if difference > best_difference or (difference == best_difference and total > best_total):
                    selected = variable
                    best_difference = difference
                    best_total = total
        if selected < 0: failed = True; break
        var chosen = -(selected + 1)
        if positive[selected] < negative[selected]: chosen = selected + 1
        if chosen > 0: assigned[selected] = 1
        else: assigned[selected] = -1
        assigned_count += 1

        for c in range(m):
            if not active[c]: continue
            var satisfied = False
            for j in range(sizes[c]):
                if clauses[3*c+j] == chosen: satisfied = True
            if satisfied:
                active[c] = False
                continue
            var kept = 0
            for j in range(sizes[c]):
                let literal = clauses[3*c+j]
                if literal != -chosen:
                    clauses[3*c+kept] = literal
                    kept += 1
            sizes[c] = kept
            if kept == 0: failed = True; break

        while not failed:
            var unit = 0
            for c in range(m):
                if unit == 0 and active[c] and sizes[c] == 1: unit = clauses[3*c]
            if unit == 0: break
            let variable = (unit if unit > 0 else -unit) - 1
            if unit > 0: assigned[variable] = 1
            else: assigned[variable] = -1
            assigned_count += 1
            for c in range(m):
                if not active[c]: continue
                var satisfied = False
                for j in range(sizes[c]):
                    if clauses[3*c+j] == unit: satisfied = True
                if satisfied:
                    active[c] = False
                    continue
                var kept = 0
                for j in range(sizes[c]):
                    let literal = clauses[3*c+j]
                    if literal != -unit:
                        clauses[3*c+kept] = literal
                        kept += 1
                sizes[c] = kept
                if kept == 0: failed = True; break

    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var fields = List[Int64](capacity=n+1)
    if failed: fields.append(0)
    else: fields.append(1)
    for variable in range(n): fields.append(Int64(assigned[variable]))
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
