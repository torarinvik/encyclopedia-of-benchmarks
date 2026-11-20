# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("suffix_automaton_kth_distinct_substring")
fn suffix_automaton_kth_distinct_substring(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 259: return -1
    let raw_n = input[0]
    var k = input[1]
    if raw_n < 1 or raw_n > 256 or length != c_size_t(raw_n+2) or k < 1: return -1
    let n = Int(raw_n)
    for i in range(n):
        if input[i+2] < 0 or input[i+2] > 255: return -1
    var transitions = InlineArray[Int32,131072](fill=-1)
    var links = InlineArray[Int32,512](fill=-1)
    var lengths = InlineArray[Int32,512](fill=0)
    var paths = InlineArray[Int64,512](fill=0)
    var count = 1
    var last = 0
    for i in range(n):
        let symbol = Int(input[i+2])
        let current = count
        count += 1
        lengths[current] = lengths[last]+1
        var p = last
        while p >= 0 and transitions[p*256+symbol] < 0:
            transitions[p*256+symbol] = Int32(current)
            p = Int(links[p])
        if p < 0: links[current] = 0
        else:
            let q = Int(transitions[p*256+symbol])
            if lengths[p]+1 == lengths[q]: links[current] = Int32(q)
            else:
                let clone = count
                count += 1
                for c in range(256): transitions[clone*256+c] = transitions[q*256+c]
                links[clone] = links[q]
                lengths[clone] = lengths[p]+1
                while p >= 0 and transitions[p*256+symbol] == Int32(q):
                    transitions[p*256+symbol] = Int32(clone)
                    p = Int(links[p])
                links[q] = Int32(clone)
                links[current] = Int32(clone)
        last = current
    var buckets = InlineArray[Int,257](fill=0)
    var order = InlineArray[Int,512](fill=0)
    for i in range(count): buckets[Int(lengths[i])] += 1
    for i in range(1,n+1): buckets[i] += buckets[i-1]
    var i = count
    while i > 0:
        i -= 1
        let l = Int(lengths[i])
        buckets[l] -= 1
        order[buckets[l]] = i
    i = count
    while i > 0:
        i -= 1
        let state = order[i]
        for c in range(256):
            let target = Int(transitions[state*256+c])
            if target >= 0: paths[state] += 1 + paths[target]
    if k > paths[0]: return -1
    var result = InlineArray[UInt8,256](fill=0)
    var used = 0
    var state = 0
    while True:
        var found = False
        for c in range(256):
            let target = Int(transitions[state*256+c])
            if target < 0: continue
            let group = 1 + paths[target]
            if k > group:
                k -= group
            else:
                result[used] = UInt8(c)
                used += 1
                state = target
                found = True
                break
        if not found: return -1
        if k == 1: break
        k -= 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(used): return -2
    for j in range(used): output[j] = result[j]
    return Int64(used)
