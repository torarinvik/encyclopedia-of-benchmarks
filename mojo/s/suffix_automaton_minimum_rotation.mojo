# Uncompiled suffix-automaton minimum-rotation draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("suffix_automaton_minimum_rotation")
fn suffix_automaton_minimum_rotation(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    let raw_n = input[0]
    if raw_n < 1 or raw_n > 256 or length != c_size_t(raw_n+1): return -1
    let n = Int(raw_n)
    for i in range(1,Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var transitions = InlineArray[Int32,262144](fill=-1)
    var links = InlineArray[Int32,1024](fill=-1)
    var lengths = InlineArray[Int32,1024](fill=0)
    var count = 1
    var last = 0
    for i in range(2*n):
        let symbol = Int(input[1+i%n])
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
    var state = 0
    for i in range(n):
        var symbol = 0
        while transitions[state*256+symbol] < 0: symbol += 1
        output[i] = UInt8(symbol)
        state = Int(transitions[state*256+symbol])
    return raw_n
