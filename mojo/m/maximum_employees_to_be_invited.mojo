from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_INPUT = 10

@export("maximum_employees_to_be_invited")
fn maximum_employees_to_be_invited(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MAX_INPUT):
        return -1
    let n = Int(input[0])
    if n < 2 or n > MAX_N or Int(length) != n + 1:
        return -1
    var favorite = InlineArray[Int64, 8](fill=0)
    var indegree = InlineArray[Int64, 8](fill=0)
    var chain = InlineArray[Int64, 8](fill=0)
    var queue = InlineArray[Int64, 8](fill=0)
    var visited = InlineArray[Bool, 8](fill=False)
    for i in range(n):
        let target = input[i + 1]
        if target < 0 or target >= n or target == i:
            return -1
        favorite[i] = target
        chain[i] = 1
        indegree[Int(target)] += 1
    var head = 0
    var tail = 0
    for i in range(n):
        if indegree[i] == 0:
            queue[tail] = i
            tail += 1
    while head < tail:
        let node = Int(queue[head])
        head += 1
        let target = Int(favorite[node])
        chain[target] = max(chain[target], chain[node] + 1)
        indegree[target] -= 1
        if indegree[target] == 0:
            queue[tail] = target
            tail += 1
    var pair_total: Int64 = 0
    var longest_cycle: Int64 = 0
    for start in range(n):
        if indegree[start] == 0 or visited[start]:
            continue
        var node = start
        var first = 0
        var second = 0
        var cycle_length = 0
        while not visited[node]:
            visited[node] = True
            if cycle_length == 0:
                first = node
            elif cycle_length == 1:
                second = node
            cycle_length += 1
            node = Int(favorite[node])
        if cycle_length == 2:
            pair_total += chain[first] + chain[second]
        elif cycle_length > longest_cycle:
            longest_cycle = cycle_length
    return max(pair_total, longest_cycle)
