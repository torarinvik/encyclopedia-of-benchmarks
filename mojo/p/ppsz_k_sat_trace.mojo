# Deterministic bounded PPSZ forcing and guess trace.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ppsz_satisfies(clauses: List[Int], m: Int, subset: Int, assignment: Int) -> Bool:
    for c in range(m):
        if (subset & (1 << c)) == 0: continue
        var satisfied = False
        for j in range(3):
            let literal = clauses[3*c+j]
            let variable = (literal if literal > 0 else -literal)-1
            let bit = (assignment >> variable) & 1
            if (literal > 0 and bit == 1) or (literal < 0 and bit == 0): satisfied = True
        if not satisfied: return False
    return True

fn ppsz_fixed(mask: Int, assigned: List[Int], n: Int) -> Int:
    var result = mask
    for i in range(n):
        if assigned[i] == 1: result |= 1 << i
        elif assigned[i] == 0: result &= ~(1 << i)
    return result

@export("ppsz_k_sat_trace")
fn ppsz_k_sat_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 54: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 3 or nv > 8 or mv < 0 or mv > 12 or length != c_size_t(2+3*mv+2*nv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var clauses = List[Int](capacity=3*m)
    var order = List[Int](capacity=n)
    var guesses = List[Int](capacity=n)
    var assigned = List[Int](capacity=n)
    for c in range(m):
        var seen = 0
        for j in range(3):
            let literal = input[2+3*c+j]
            if literal == 0 or literal < -nv or literal > nv: return -1
            let variable = Int(literal if literal > 0 else -literal)-1
            if (seen & (1 << variable)) != 0: return -1
            seen |= 1 << variable
            clauses.append(Int(literal))
    let start = 2+3*m
    var seen = 0
    for i in range(n):
        let value = input[start+i]
        if value < 0 or value >= nv or (seen & (1 << Int(value))) != 0: return -1
        seen |= 1 << Int(value)
        order.append(Int(value)); assigned.append(-1)
    for i in range(n):
        let value = input[start+n+i]
        if value != 0 and value != 1: return -1
        guesses.append(Int(value))
    var threshold = 0
    while (1 << (threshold+1)) <= n: threshold += 1
    let all_clauses = (1 << m)-1
    for step in range(n):
        while True:
            var consistent = False
            for mask in range(1 << n):
                if ppsz_satisfies(clauses,m,all_clauses,ppsz_fixed(mask,assigned,n)):
                    consistent = True
                    break
            if not consistent: break
            var implied = List[Int](capacity=n)
            for _ in range(n): implied.append(-1)
            for subset in range(1,1 << m):
                var bits = subset
                var bit_count = 0
                while bits != 0:
                    bit_count += bits & 1
                    bits >>= 1
                if bit_count > threshold: continue
                var zero = 0
                var one = 0
                for mask in range(1 << n):
                    let full = ppsz_fixed(mask,assigned,n)
                    if ppsz_satisfies(clauses,m,subset,full):
                        one |= full
                        zero |= (~full) & ((1 << n)-1)
                for variable in range(n):
                    if assigned[variable] < 0 and implied[variable] < 0:
                        let can_zero = (zero & (1 << variable)) != 0
                        let can_one = (one & (1 << variable)) != 0
                        if can_zero != can_one:
                            if can_one: implied[variable] = 1
                            else: implied[variable] = 0
            var forced = -1
            for variable in range(n):
                if implied[variable] >= 0:
                    forced = variable
                    break
            if forced < 0: break
            assigned[forced] = implied[forced]
        let variable = order[step]
        if assigned[variable] < 0: assigned[variable] = guesses[variable]
    var final_mask = 0
    for i in range(n):
        if assigned[i] == 1: final_mask |= 1 << i
    var fields = List[Int64](capacity=n+1)
    if ppsz_satisfies(clauses,m,all_clauses,final_mask): fields.append(1)
    else: fields.append(0)
    for i in range(n): fields.append(Int64(assigned[i]))
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
