# Unit-first, occurrence-greedy DPLL without backtracking.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("random_3sat_greedy_dpll")
fn random_3sat_greedy_dpll(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 3 or nv > 12 or mv < 0 or mv > 32 or length != c_size_t(2+3*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var clauses = List[Int](capacity=3*m)
    var sizes = List[Int](capacity=m)
    var active = List[Bool](capacity=m)
    var assigned = List[Int64](capacity=n)
    for _ in range(n): assigned.append(0)
    for c in range(m):
        var seen = 0
        for j in range(3):
            let lit = input[2+3*c+j]
            if lit == 0 or lit < -nv or lit > nv: return -1
            let variable = Int(lit if lit > 0 else -lit)-1
            if (seen & (1 << variable)) != 0: return -1
            seen |= 1 << variable
            clauses.append(Int(lit))
        sizes.append(3); active.append(True)
    var failed = False
    for _ in range(n):
        if failed: break
        var remaining = 0
        for c in range(m):
            if active[c]: remaining += 1
        if remaining == 0: break
        var chosen = 0
        for c in range(m):
            if chosen == 0 and active[c] and sizes[c] == 1: chosen = clauses[3*c]
        if chosen == 0:
            var counts = List[Int](capacity=2*n)
            for _ in range(2*n): counts.append(0)
            for c in range(m):
                if not active[c]: continue
                for j in range(sizes[c]):
                    let lit = clauses[3*c+j]
                    let variable = (lit if lit > 0 else -lit)-1
                    var sign = 0
                    if lit < 0: sign = 1
                    counts[2*variable+sign] += 1
            var best = 0
            for variable in range(n):
                for sign in range(2):
                    let count = counts[2*variable+sign]
                    if count > best:
                        best = count
                        chosen = variable+1
                        if sign == 1: chosen = -chosen
        if chosen == 0:
            failed = True
            break
        let variable = (chosen if chosen > 0 else -chosen)-1
        if chosen > 0: assigned[variable] = 1
        else: assigned[variable] = -1
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
                let lit = clauses[3*c+j]
                if lit != -chosen:
                    clauses[3*c+kept] = lit
                    kept += 1
            sizes[c] = kept
            if kept == 0:
                failed = True
                break
    var success = not failed
    for c in range(m):
        if active[c]: success = False
    if success:
        for i in range(n):
            if assigned[i] == 0: assigned[i] = -1
    var fields = List[Int64](capacity=n+1)
    if success: fields.append(1)
    else: fields.append(0)
    for i in range(n): fields.append(assigned[i])
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
