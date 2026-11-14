from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("approximate_regex_matching")
fn approximate_regex_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 66: return -1
    let sv = input[0]
    let ev = input[1]
    let tv = input[2]
    let kv = input[3]
    let stv = input[4]
    let av = input[5]
    if sv < 2 or sv > 8 or ev < 1 or ev > 16 or tv < 0 or tv > 12 or kv < 0 or kv > 3: return -1
    if stv < 0 or stv >= sv or av < 0 or av >= sv or stv == av: return -1
    let states = Int(sv)
    let edges = Int(ev)
    let text_length = Int(tv)
    let limit = Int(kv)
    let start = Int(stv)
    let accept = Int(av)
    let text_start = 6+3*edges
    if length != c_size_t(text_start+text_length): return -1
    var sources = List[Int](capacity=16)
    var targets = List[Int](capacity=16)
    var labels = List[Int64](capacity=16)
    for i in range(edges):
        let u = input[6+3*i]
        let v = input[7+3*i]
        let label = input[8+3*i]
        if u < 0 or u >= sv or v < 0 or v >= sv or label < 1 or label > 127: return -1
        for j in range(i):
            if sources[j] == Int(u) and targets[j] == Int(v) and labels[j] == label: return -1
        sources.append(Int(u))
        targets.append(Int(v))
        labels.append(label)
    for i in range(text_length):
        if input[text_start+i] < 1 or input[text_start+i] > 127: return -1
    if capacity < c_size_t(text_length) or (text_length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    let infinity = limit+1
    var current = List[Int](capacity=8)
    var next = List[Int](capacity=8)
    for _ in range(8):
        current.append(infinity)
        next.append(infinity)
    for pos in range(text_length):
        current[start] = 0
        for _ in range(states-1):
            var changed = False
            for edge in range(edges):
                let value = current[sources[edge]]+1
                if current[sources[edge]] < infinity and value < current[targets[edge]]:
                    current[targets[edge]] = value
                    changed = True
            if not changed: break
        for state in range(states):
            next[state] = min(infinity, current[state]+1)
        for edge in range(edges):
            if current[sources[edge]] < infinity:
                var cost = current[sources[edge]]
                if labels[edge] != input[text_start+pos]: cost += 1
                if cost < next[targets[edge]]: next[targets[edge]] = cost
        for _ in range(states-1):
            var changed = False
            for edge in range(edges):
                let value = next[sources[edge]]+1
                if next[sources[edge]] < infinity and value < next[targets[edge]]:
                    next[targets[edge]] = value
                    changed = True
            if not changed: break
        output[pos] = UInt8(next[accept] <= limit)
        for state in range(states): current[state] = next[state]
    return Int64(text_length)
