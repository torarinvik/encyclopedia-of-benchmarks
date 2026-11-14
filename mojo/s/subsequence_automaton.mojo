# Uncompiled and unexecuted next-occurrence automaton draft.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("subsequence_automaton")
fn subsequence_automaton(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 354: return -1
    if input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let queries = Int(input[1])
    if Int(length) < 2+n: return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 3: return -1
    var next = List[Int](length=260, fill=0)
    for c in range(4): next[4*n+c] = n
    var row = n
    while row > 0:
        row -= 1
        for c in range(4): next[4*row+c] = next[4*(row+1)+c]
        next[4*row+Int(input[2+row])] = row
    var pos = 2+n
    var total = 0
    var answer: Int64 = 0
    for q in range(queries):
        if pos == Int(length) or input[pos] < 0 or input[pos] > 256: return -1
        let count = Int(input[pos])
        pos += 1
        if count > 256-total or count > Int(length)-pos: return -1
        var cursor = 0
        var matches = True
        for i in range(count):
            let symbol = input[pos+i]
            if symbol < 0 or symbol > 3: return -1
            if matches:
                let found = next[4*cursor+Int(symbol)]
                if found == n: matches = False
                else: cursor = found+1
        if matches: answer += Int64(q+1)
        pos += count
        total += count
    return answer if pos == Int(length) else -1
