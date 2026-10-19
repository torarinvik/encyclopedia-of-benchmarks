from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("area_of_polygon_benchmark")
fn area_of_polygon_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1026:
        return -1
    let polygon_count = values[0]
    if polygon_count < 0 or polygon_count > 32:
        return -1
    var cursor = 1
    var total_vertices = 0
    for polygon in range(Int(polygon_count)):
        if cursor >= Int(length): return -1
        let vertex_count = values[cursor]
        cursor += 1
        if vertex_count < 3 or vertex_count > 128: return -1
        if total_vertices + Int(vertex_count) > 512 or 2 * Int(vertex_count) > Int(length) - cursor: return -1
        for vertex in range(Int(vertex_count)):
            let x = values[cursor + 2 * vertex]
            let y = values[cursor + 2 * vertex + 1]
            if x < -1000000 or x > 1000000 or y < -1000000 or y > 1000000: return -1
        cursor += 2 * Int(vertex_count)
        total_vertices += Int(vertex_count)
    if cursor != Int(length): return -1
    cursor = 1
    var checksum: Int64 = 0
    for polygon in range(Int(polygon_count)):
        let vertices = Int(values[cursor])
        cursor += 1
        let points = cursor
        var previous_x = values[points + 2 * (vertices - 1)]
        var previous_y = values[points + 2 * (vertices - 1) + 1]
        var cross_sum: Int64 = 0
        for vertex in range(vertices):
            let current_x = values[points + 2 * vertex]
            let current_y = values[points + 2 * vertex + 1]
            cross_sum += previous_x * current_y - current_x * previous_y
            previous_x = current_x
            previous_y = current_y
        var doubled_area = cross_sum
        if doubled_area < 0: doubled_area = -doubled_area
        checksum += Int64(polygon + 1) * (doubled_area + 1000000007)
        cursor += 2 * vertices
    return checksum
