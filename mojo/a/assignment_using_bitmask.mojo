from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("assignment_using_bitmask")
fn assignment_using_bitmask(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let people = input[0]
    let tasks = input[1]
    if people < 0 or people > 10 or tasks < 0 or tasks > 10 or length != c_size_t(2 + people):
        return -1
    let valid = 1 << Int(tasks)
    for person in range(Int(people)):
        if input[2 + person] < 0 or input[2 + person] >= Int64(valid):
            return -1
    let states = 1 << Int(people)
    var ways = List[Int64](length=1024, fill=0)
    var next = List[Int64](length=1024, fill=0)
    ways[0] = 1
    for task in range(Int(tasks)):
        for mask in range(states):
            next[mask] = 0
        for mask in range(states):
            let count = ways[mask]
            if count == 0:
                continue
            next[mask] += count
            for person in range(Int(people)):
                let bit = 1 << person
                if (mask & bit) == 0 and (input[2 + person] & Int64(1 << task)) != 0:
                    next[mask | bit] += count
        for mask in range(states):
            ways[mask] = next[mask]
    return ways[states - 1]
