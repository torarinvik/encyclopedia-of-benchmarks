from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("binary_decision_graph")
fn binary_decision_graph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 6: return -1
    let n = Int(nv)
    let count = 1 << n
    if length != c_size_t(1+count): return -1
    var ids = List[Int64](capacity=64)
    var next = List[Int64](capacity=64)
    var variables = List[Int64](capacity=63)
    var lows = List[Int64](capacity=63)
    var highs = List[Int64](capacity=63)
    for i in range(64):
        ids.append(0)
        next.append(0)
        if i < 63:
            variables.append(0)
            lows.append(0)
            highs.append(0)
    for i in range(count):
        let value = input[1+i]
        if value != 0 and value != 1: return -1
        ids[i] = value
    var nodes = 0
    var current_count = count
    for step in range(n):
        let variable = n-1-step
        let next_count = current_count//2
        for pair in range(next_count):
            let low = ids[2*pair]
            let high = ids[2*pair+1]
            if low == high:
                next[pair] = low
                continue
            var found = nodes
            var j = nodes
            while j > 0:
                j -= 1
                if variables[j] != Int64(variable): break
                if lows[j] == low and highs[j] == high:
                    found = j
                    break
            if found == nodes:
                variables[nodes] = Int64(variable)
                lows[nodes] = low
                highs[nodes] = high
                nodes += 1
            next[pair] = Int64(2+found)
        for i in range(next_count): ids[i] = next[i]
        current_count = next_count
    let bytes = 8*(2+3*nodes)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, ids[0])
    put_word(output, 8, Int64(nodes))
    for i in range(nodes):
        let offset = 16+24*i
        put_word(output, offset, variables[i])
        put_word(output, offset+8, lows[i])
        put_word(output, offset+16, highs[i])
    return Int64(bytes)
