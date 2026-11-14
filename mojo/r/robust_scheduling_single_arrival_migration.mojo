# Bounded robust-scheduling transition with exact optimum validation.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("robust_scheduling_single_arrival_migration")
fn robust_scheduling_single_arrival_migration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 20: return -1
    let mv = input[0]; let nv = input[1]; let claimed = input[2]; let new_size = input[3]
    if mv < 2 or mv > 3 or nv < 1 or nv > 8 or claimed < 1 or new_size < 1 or new_size > 20 or length != c_size_t(4+2*nv): return -1
    let m = Int(mv); let n = Int(nv)
    var sizes = List[Int64](capacity=n+1)
    var assignment = List[Int](capacity=n+1)
    var loads = List[Int64](capacity=m)
    var removed = List[Bool](capacity=n)
    for _ in range(m): loads.append(0)
    for i in range(n):
        let size = input[4+2*i]; let machine = input[5+2*i]
        if size < 1 or size > 20 or machine < 0 or machine >= mv: return -1
        sizes.append(size); assignment.append(Int(machine)); removed.append(False)
        loads[Int(machine)] += size
    sizes.append(new_size); assignment.append(0)
    var possibilities = 1
    for _ in range(n+1): possibilities *= m
    var optimum = Int64(181)
    for code in range(possibilities):
        var trial = List[Int64](capacity=m)
        for _ in range(m): trial.append(0)
        var digits = code
        for i in range(n+1):
            let target = digits%m
            digits //= m
            trial[target] += sizes[i]
        var makespan = Int64(0)
        for machine in range(m):
            if trial[machine] > makespan: makespan = trial[machine]
        if makespan < optimum: optimum = makespan
    if optimum != claimed: return -1
    var moved = Int64(0)
    if 2*new_size <= optimum:
        var target = 0
        for machine in range(1,m):
            if loads[machine] < loads[target]: target = machine
        assignment[n] = target
        loads[target] += new_size
    else:
        var source = -1
        for machine in range(m):
            var eligible = True
            var volume = Int64(0)
            for i in range(n):
                if assignment[i] == machine:
                    if 2*sizes[i] > optimum: eligible = False
                    volume += sizes[i]
            if eligible and volume >= new_size:
                source = machine
                break
        if source < 0: return -1
        var volume = Int64(0)
        for i in range(n):
            if assignment[i] == source:
                removed[i] = True
                volume += sizes[i]
                loads[source] -= sizes[i]
                if volume >= new_size: break
        assignment[n] = source
        loads[source] += new_size
        for i in range(n):
            if removed[i]:
                var target = 0
                for machine in range(1,m):
                    if loads[machine] < loads[target]: target = machine
                assignment[i] = target
                loads[target] += sizes[i]
                if target != source: moved += sizes[i]
    var fields = List[Int64](capacity=n+3)
    fields.append(optimum); fields.append(moved)
    for i in range(n+1): fields.append(Int64(assignment[i]))
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
