from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("bitmask_assignment_count")
fn bitmask_assignment_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 106: return -1
    let pv = input[0]; let tv = input[1]
    if pv < 0 or pv > 8 or tv < 0 or tv > 12: return -1
    let people = Int(pv); let tasks = Int(tv)
    var freq = List[Int64](capacity=13 * 8); for _ in range(13 * 8): freq.append(0)
    var pos = 2
    for person in range(people):
        if pos >= Int(length): return -1
        let cv = input[pos]; pos += 1
        if cv < 0 or cv > 12 or pos + Int(cv) > Int(length): return -1
        for _ in range(Int(cv)):
            let task = input[pos]; pos += 1
            if task < 1 or task > tv: return -1
            freq[Int(task) * 8 + person] += 1
    if pos != Int(length): return -1
    let states = 1 << people; let full = states - 1
    var dp = List[Int64](capacity=states); for _ in range(states): dp.append(0)
    dp[0] = 1
    for task in range(1, tasks + 1):
        var next = List[Int64](capacity=states); for _ in range(states): next.append(0)
        for mask in range(states):
            next[mask] += dp[mask]
            for person in range(people):
                if (mask & (1 << person)) == 0:
                    next[mask | (1 << person)] += dp[mask] * freq[task * 8 + person]
        dp = next
    return dp[full]
