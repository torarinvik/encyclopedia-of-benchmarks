from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_PROCESSES = 16
comptime MAX_RESOURCES = 8

@export("bankers_algorithm")
fn bankers_algorithm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 266:
        return -1
    let process_value = input[0]
    let resource_value = input[1]
    if process_value < 1 or process_value > MAX_PROCESSES or resource_value < 1 or resource_value > MAX_RESOURCES:
        return -1
    let processes = Int(process_value)
    let resources = Int(resource_value)
    let maximum_offset = 2 + resources
    let allocation_offset = maximum_offset + processes * resources
    if length != c_size_t(allocation_offset + processes * resources):
        return -1
    var work = List[Int64](capacity=MAX_RESOURCES)
    for resource in range(resources):
        let available = input[2 + resource]
        if available < 0 or available > 100:
            return -1
        work.append(available)
    for process in range(processes):
        for resource in range(resources):
            let index = process * resources + resource
            let maximum = input[maximum_offset + index]
            let allocation = input[allocation_offset + index]
            if maximum < 0 or maximum > 100 or allocation < 0 or allocation > maximum:
                return -1
    var finished = List[Bool](capacity=MAX_PROCESSES)
    for _ in range(processes):
        finished.append(False)
    var completed = 0
    while completed < processes:
        var progress = False
        for process in range(processes):
            if finished[process]:
                continue
            var feasible = True
            for resource in range(resources):
                let index = process * resources + resource
                if input[maximum_offset + index] - input[allocation_offset + index] > work[resource]:
                    feasible = False
                    break
            if feasible:
                for resource in range(resources):
                    work[resource] += input[allocation_offset + process * resources + resource]
                finished[process] = True
                completed += 1
                progress = True
        if not progress:
            return 0
    return 1
