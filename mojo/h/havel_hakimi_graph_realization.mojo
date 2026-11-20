from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_EDGES = 28
const MAX_INPUT = 10

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("havel_hakimi_graph_realization")
fn havel_hakimi_graph_realization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT: return -1
    let n64 = input[0]
    if n64 < 0 or n64 > MAX_N: return -1
    let n = Int(n64)
    if length != c_size_t(n + 1): return -1
    var residual = InlineArray[Int64, 8]()
    var active = InlineArray[Bool, 8]()
    for vertex in range(n):
        let d = input[vertex + 1]
        if d < 0 or d >= n64: return -1
        residual[vertex] = d
        active[vertex] = True
    var edges_left = InlineArray[Int64, 28]()
    var edges_right = InlineArray[Int64, 28]()
    var edge_count = 0
    var graphical = True
    while graphical:
        var hub = -1
        for vertex in range(n):
            if active[vertex] and residual[vertex] > 0:
                if hub < 0 or residual[vertex] > residual[hub] or (residual[vertex] == residual[hub] and vertex < hub):
                    hub = vertex
        if hub < 0: break
        let d = Int(residual[hub])
        residual[hub] = 0
        active[hub] = False
        var candidates = InlineArray[Int, 8]()
        var candidate_count = 0
        for vertex in range(n):
            if active[vertex]:
                candidates[candidate_count] = vertex
                candidate_count += 1
        for index in range(1, candidate_count):
            let value = candidates[index]
            var j = index
            while j > 0 and (residual[candidates[j - 1]] < residual[value] or (residual[candidates[j - 1]] == residual[value] and candidates[j - 1] > value)):
                candidates[j] = candidates[j - 1]
                j -= 1
            candidates[j] = value
        if d > candidate_count:
            graphical = False
            break
        for index in range(d):
            let neighbor = candidates[index]
            if residual[neighbor] == 0:
                graphical = False
                break
            residual[neighbor] -= 1
            edges_left[edge_count] = Int64(hub if hub < neighbor else neighbor)
            edges_right[edge_count] = Int64(neighbor if hub < neighbor else hub)
            edge_count += 1
    var words = InlineArray[Int64, 58]()
    var word_count = 0
    if graphical:
        words[0] = 1
        words[1] = Int64(edge_count)
        word_count = 2 + 2 * edge_count
        for index in range(edge_count):
            words[2 + 2 * index] = edges_left[index]
            words[3 + 2 * index] = edges_right[index]
    else:
        words[0] = 0
        word_count = 1
    let byte_count = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    var encoded = InlineArray[UInt8, 464]()
    for index in range(word_count): store_i64(encoded.unsafe_ptr(), index * 8, words[index])
    for index in range(byte_count): output[index] = encoded[index]
    Int64(byte_count)
