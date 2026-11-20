from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("brzozowski_dfa_minimization")
fn brzozowski_dfa_minimization(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 10:
        return -1
    let n64 = input[0]
    let start64 = input[1]
    let accepting64 = input[2]
    if n64 < 1 or n64 > 3 or start64 < 0 or start64 >= n64:
        return -1
    if accepting64 < 0 or accepting64 >= (Int64(1) << Int(n64)):
        return -1
    let n = Int(n64)
    if length != c_size_t(3 + 2 * n):
        return -1

    var transitions = List[Int](length=6, fill=0)
    for state in range(n):
        for symbol in range(2):
            let target = input[3 + 2 * state + symbol]
            if target < 0 or target >= n64:
                return -1
            transitions[state * 2 + symbol] = Int(target)

    var first_masks = List[Int](length=8, fill=0)
    var first_delta = List[Int](length=16, fill=0)
    var first_final = List[Int](length=8, fill=0)
    var first_id = List[Int](length=8, fill=-1)
    var first_count = 1
    first_masks[0] = Int(accepting64)
    first_id[Int(accepting64)] = 0
    var cursor = 0
    while cursor < first_count:
        let subset = first_masks[cursor]
        first_final[cursor] = (subset >> Int(start64)) & 1
        for symbol in range(2):
            var predecessor = 0
            for state in range(n):
                if (subset & (1 << transitions[state * 2 + symbol])) != 0:
                    predecessor |= 1 << state
            if first_id[predecessor] < 0:
                first_id[predecessor] = first_count
                first_masks[first_count] = predecessor
                first_count += 1
            first_delta[cursor * 2 + symbol] = first_id[predecessor]
        cursor += 1

    var first_accepting = 0
    for state in range(first_count):
        if first_final[state] != 0:
            first_accepting |= 1 << state

    var second_queue = List[Int](length=256, fill=0)
    var second_seen = List[Int](length=256, fill=0)
    var second_count = 1
    second_queue[0] = first_accepting
    second_seen[first_accepting] = 1
    cursor = 0
    while cursor < second_count:
        let subset = second_queue[cursor]
        for symbol in range(2):
            var predecessor = 0
            for state in range(first_count):
                if (subset & (1 << first_delta[state * 2 + symbol])) != 0:
                    predecessor |= 1 << state
            if second_seen[predecessor] == 0:
                second_seen[predecessor] = 1
                second_queue[second_count] = predecessor
                second_count += 1
        cursor += 1
    return Int64(second_count)
