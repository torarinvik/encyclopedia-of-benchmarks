from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_VERTICES = 64
comptime MAX_INPUT_EDGES = 256
comptime MAX_NORMALIZED_EDGES = 128

fn append_i64_le(mut out: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        out.append(UInt8(bits & 255))
        bits >>= 8

fn write_pair(output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
              status: Int64, reachable: Int64, distance: Int64) -> Int64:
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    var bytes = List[UInt8](capacity=24)
    append_i64_le(bytes, status)
    append_i64_le(bytes, reachable)
    append_i64_le(bytes, distance)
    for i in range(24): output[i] = bytes[i]
    return 24

@export("bellman_ford_pair")
fn bellman_ford_pair(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let vertices_value = input[0]
    let input_edges_value = input[1]
    let source_value = input[2]
    let target_value = input[3]
    if vertices_value < 1 or vertices_value > MAX_VERTICES or input_edges_value < 0 or input_edges_value > MAX_INPUT_EDGES: return -1
    if source_value < 0 or source_value >= vertices_value or target_value < 0 or target_value >= vertices_value or
       length != c_size_t(4 + 3 * input_edges_value): return -1
    let vertices = Int(vertices_value)
    let input_edges = Int(input_edges_value)
    var present = List[Bool](capacity=MAX_VERTICES * MAX_VERTICES)
    var weights = List[Int64](capacity=MAX_VERTICES * MAX_VERTICES)
    for _ in range(MAX_VERTICES * MAX_VERTICES):
        present.append(False)
        weights.append(0)
    var normalized = 0
    for edge in range(input_edges):
        let from = input[4 + 3 * edge]
        let to = input[5 + 3 * edge]
        let weight = input[6 + 3 * edge]
        if from < 0 or from >= vertices_value or to < 0 or to >= vertices_value or weight < -1000 or weight > 1000: return -1
        let key = Int(from) * vertices + Int(to)
        if not present[key]:
            present[key] = True
            normalized += 1
            if normalized > MAX_NORMALIZED_EDGES: return -1
        weights[key] = weight
    var froms = List[Int](capacity=MAX_NORMALIZED_EDGES)
    var tos = List[Int](capacity=MAX_NORMALIZED_EDGES)
    var edge_weights = List[Int64](capacity=MAX_NORMALIZED_EDGES)
    for from in range(vertices):
        for to in range(vertices):
            let key = from * vertices + to
            if present[key]:
                froms.append(from)
                tos.append(to)
                edge_weights.append(weights[key])
    var distances = List[Int64](capacity=MAX_VERTICES)
    var reached = List[Bool](capacity=MAX_VERTICES)
    for _ in range(MAX_VERTICES):
        distances.append(0)
        reached.append(False)
    let source = Int(source_value)
    reached[source] = True
    for _ in range(vertices):
        var changed = False
        for edge in range(len(froms)):
            let from = froms[edge]
            let to = tos[edge]
            if not reached[from]: continue
            let candidate = distances[from] + edge_weights[edge]
            if not reached[to] or candidate < distances[to]:
                distances[to] = candidate
                reached[to] = True
                changed = True
        if not changed: break
    for edge in range(len(froms)):
        let from = froms[edge]
        let to = tos[edge]
        if reached[from] and distances[to] > distances[from] + edge_weights[edge]:
            return write_pair(output, capacity, -1, 0, 0)
    let target = Int(target_value)
    return write_pair(output, capacity, 0, 1 if reached[target] else 0, distances[target] if reached[target] else 0)
