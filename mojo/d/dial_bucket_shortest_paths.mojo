from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_VERTICES = 16
comptime MAX_EDGES = 64
comptime MAX_DISTANCE = 120
comptime BUCKETS = 9
comptime MAX_INPUT = 196

fn dial_enqueue(inout record_vertex: InlineArray[Int64, 65],
                inout record_distance: InlineArray[Int64, 65],
                inout record_next: InlineArray[Int64, 65],
                inout bucket_head: InlineArray[Int64, 9],
                inout bucket_tail: InlineArray[Int64, 9],
                inout used: Int, vertex: Int, distance: Int64):
    let record = used
    record_vertex[record] = Int64(vertex)
    record_distance[record] = distance
    record_next[record] = -1
    let bucket = Int(distance % 9)
    if bucket_tail[bucket] < 0:
        bucket_head[bucket] = Int64(record)
        bucket_tail[bucket] = Int64(record)
    else:
        let previous = Int(bucket_tail[bucket])
        record_next[previous] = Int64(record)
        bucket_tail[bucket] = Int64(record)
    used += 1

@export("dial_bucket_shortest_paths")
fn dial_bucket_shortest_paths(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t,
                              out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < c_size_t(3) or n > c_size_t(MAX_INPUT):
        return -1
    let vertex_count_value = v[0]
    let edge_count_value = v[1]
    let source_value = v[2]
    if vertex_count_value < 1 or vertex_count_value > MAX_VERTICES or
       edge_count_value < 0 or edge_count_value > MAX_EDGES:
        return -1
    let vertex_count = Int(vertex_count_value)
    let edge_count = Int(edge_count_value)
    if source_value < 0 or source_value >= vertex_count_value or n != c_size_t(3 + 3 * edge_count):
        return -1

    var edge_head = InlineArray[Int64, 16](fill=-1)
    var edge_to = InlineArray[Int64, 64](fill=0)
    var edge_weight = InlineArray[Int64, 64](fill=0)
    var edge_next = InlineArray[Int64, 64](fill=0)
    var cursor = 3
    for edge in range(edge_count):
        let from_value = v[cursor]
        let to_value = v[cursor + 1]
        let weight = v[cursor + 2]
        if from_value < 0 or from_value >= vertex_count_value or to_value < 0 or to_value >= vertex_count_value or
           weight < 0 or weight > 8:
            return -1
        let from_vertex = Int(from_value)
        edge_to[edge] = to_value
        edge_weight[edge] = weight
        edge_next[edge] = edge_head[from_vertex]
        edge_head[from_vertex] = Int64(edge)
        cursor += 3

    let required = 8 * vertex_count
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(required):
        return -2

    var distance = InlineArray[Int64, 16](fill=MAX_DISTANCE + 1)
    var settled = InlineArray[Bool, 16](fill=False)
    let source = Int(source_value)
    distance[source] = 0
    var record_vertex = InlineArray[Int64, 65](fill=0)
    var record_distance = InlineArray[Int64, 65](fill=0)
    var record_next = InlineArray[Int64, 65](fill=-1)
    var bucket_head = InlineArray[Int64, 9](fill=-1)
    var bucket_tail = InlineArray[Int64, 9](fill=-1)
    var used = 0
    dial_enqueue(inout record_vertex, inout record_distance, inout record_next,
                 inout bucket_head, inout bucket_tail, inout used, source, 0)

    for current in range(MAX_DISTANCE + 1):
        let bucket = current % BUCKETS
        while bucket_head[bucket] >= 0:
            let record = Int(bucket_head[bucket])
            bucket_head[bucket] = record_next[record]
            if bucket_head[bucket] < 0: bucket_tail[bucket] = -1
            let vertex = Int(record_vertex[record])
            if record_distance[record] != current or settled[vertex] or distance[vertex] != current:
                continue
            settled[vertex] = True
            var edge = Int(edge_head[vertex])
            while edge >= 0:
                let target = Int(edge_to[edge])
                let candidate = Int64(current) + edge_weight[edge]
                if not settled[target] and candidate < distance[target]:
                    distance[target] = candidate
                    dial_enqueue(inout record_vertex, inout record_distance, inout record_next,
                                 inout bucket_head, inout bucket_tail, inout used, target, candidate)
                edge = Int(edge_next[edge])

    var staged = InlineArray[UInt8, 128](fill=0)
    for vertex in range(vertex_count):
        var value = distance[vertex]
        if value > MAX_DISTANCE: value = -1
        for byte in range(8):
            if value < 0:
                staged[vertex * 8 + byte] = UInt8(255)
            else:
                staged[vertex * 8 + byte] = UInt8((value >> (8 * byte)) & 255)
    for byte in range(required): out[byte] = staged[byte]
    return Int64(required)
