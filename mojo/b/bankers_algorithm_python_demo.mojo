from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_M = 8

@export("bankers_algorithm_python_demo")
fn bankers_algorithm_python_demo(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 266:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 1 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let allocation_offset = 2 + m
    let maximum_offset = 2 + m + n * m
    if length != c_size_t(maximum_offset + n * m):
        return -1
    var work = List[Int64](capacity=MAX_M)
    for resource in range(m):
        let claim = input[2 + resource]
        if claim < 0 or claim > 100:
            return -1
        work.append(claim)
    for process in range(n):
        for resource in range(m):
            let index = process * m + resource
            let allocation = input[allocation_offset + index]
            let maximum = input[maximum_offset + index]
            if allocation < 0 or allocation > 100 or maximum < 0 or maximum > 100 or allocation > maximum:
                return -1
            work[resource] -= allocation
    for resource in range(m):
        if work[resource] < 0:
            return -1
    var first = List[Int](capacity=MAX_N)
    var remaining = List[Int](capacity=MAX_N)
    for process in range(n):
        first.append(process)
        remaining.append(process)
        for earlier in range(process):
            var equal = True
            for resource in range(m):
                let pi = process * m + resource
                let qi = earlier * m + resource
                if input[maximum_offset + pi] - input[allocation_offset + pi] != input[maximum_offset + qi] - input[allocation_offset + qi]:
                    equal = False
                    break
            if equal:
                first[process] = first[earlier]
                break
    var count = n
    while count > 0:
        var selected = count
        for position in range(count):
            let process = remaining[position]
            var feasible = True
            for resource in range(m):
                let index = process * m + resource
                if input[maximum_offset + index] - input[allocation_offset + index] > work[resource]:
                    feasible = False
                    break
            if feasible:
                selected = position
                break
        if selected == count:
            return 0
        let mapped = first[remaining[selected]]
        for resource in range(m):
            work[resource] += input[allocation_offset + mapped * m + resource]
        for position in range(selected + 1, count):
            remaining[position - 1] = remaining[position]
        count -= 1
    return 1
