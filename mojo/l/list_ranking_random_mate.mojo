# Weighted list ranking with supplied random-mate coin flips.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("list_ranking_random_mate")
fn list_ranking_random_mate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 275: return -1
    let n64 = input[0]
    let head64 = input[1]
    if n64 < 1 or n64 > 8 or head64 < 0 or head64 >= n64: return -1
    let n = Int(n64)
    let head = Int(head64)
    if length < c_size_t(3 + 2*n): return -1
    let rounds64 = input[2 + 2*n]
    if rounds64 < 0 or rounds64 > 32 or length != c_size_t(3 + 2*n64 + rounds64*n64): return -1
    let rounds = Int(rounds64)

    var weights = List[Int64](capacity=n)
    var successors = List[Int](capacity=n)
    var indegree = List[Int](capacity=n)
    for _ in range(n): indegree.append(0)
    var tails = 0
    for index in range(n):
        let weight = input[2 + index]
        let successor = input[2 + n + index]
        if weight < 1 or weight > 10000 or successor < -1 or successor >= n64: return -1
        weights.append(weight)
        successors.append(Int(successor))
        if successor == -1:
            tails += 1
        else:
            let target = Int(successor)
            indegree[target] += 1
            if indegree[target] > 1: return -1
    if tails != 1 or indegree[head] != 0: return -1
    let coinStart = 3 + 2*n
    for index in range(rounds*n):
        let coin = input[coinStart + index]
        if coin < 0 or coin > 1: return -1

    var seen = List[Bool](capacity=n)
    for _ in range(n): seen.append(False)
    var pathLength = 0
    var node = head
    while node != -1:
        if seen[node] or pathLength == n: return -1
        seen[node] = True
        pathLength += 1
        node = successors[node]
    if pathLength != n: return -1

    var active = List[Bool](capacity=n)
    var removalRound = List[Int](capacity=n)
    var ranks = List[Int64](capacity=n)
    for index in range(n):
        active.append(True)
        removalRound.append(-1)
        ranks.append(0)
    for round in range(rounds):
        if successors[head] == -1: break
        var oldSuccessors = List[Int](capacity=n)
        var oldWeights = List[Int64](capacity=n)
        var remove = List[Bool](capacity=n)
        for index in range(n):
            oldSuccessors.append(successors[index])
            oldWeights.append(weights[index])
            remove.append(False)
        let coinOffset = coinStart + round*n
        for index in range(n):
            let target = oldSuccessors[index]
            if active[index] and target != -1 and input[coinOffset + index] == 0 and input[coinOffset + target] == 1:
                remove[target] = True
                removalRound[target] = round
        for index in range(n):
            let target = oldSuccessors[index]
            if active[index] and target != -1 and remove[target]:
                weights[index] = oldWeights[index] + oldWeights[target]
                successors[index] = oldSuccessors[target]
        for index in range(n):
            if remove[index]: active[index] = False
    if successors[head] != -1: return -1

    for index in range(n): ranks[index] = weights[index]
    for remaining in range(rounds):
        let round = rounds - 1 - remaining
        for index in range(n):
            if removalRound[index] == round and successors[index] != -1:
                ranks[index] += ranks[successors[index]]
    let outputBytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(outputBytes): return -2
    for index in range(n):
        var bits = UInt64(ranks[index])
        for byte in range(8):
            output[8*index + byte] = UInt8(bits & 255)
            bits = bits >> 8
    return Int64(outputBytes)
