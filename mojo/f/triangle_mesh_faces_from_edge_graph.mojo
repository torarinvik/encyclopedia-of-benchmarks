from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES = 8
const MAX_EDGES = 28
const MAX_TRIANGLES = 56
const MAX_INPUT_WORDS = 59
const MAX_OUTPUT_WORDS = 170

struct FaceTriangle(Copyable):
    var a: Int = 0
    var b: Int = 0
    var c: Int = 0
    var e0: Int = 0
    var e1: Int = 0
    var e2: Int = 0
    var active: Bool = False

fn face_select(chosen: Int, inout triangles: InlineArray[FaceTriangle, MAX_TRIANGLES],
    triangle_count: Int, inout incidence: InlineArray[Int, MAX_EDGES],
    inout used: InlineArray[Int, MAX_EDGES],
    inout staged: InlineArray[Int64, MAX_OUTPUT_WORDS], inout face_count: Int):
    var triangle = triangles[chosen]
    triangles[chosen].active = False
    staged[2 + 3 * face_count] = Int64(triangle.a)
    staged[3 + 3 * face_count] = Int64(triangle.b)
    staged[4 + 3 * face_count] = Int64(triangle.c)
    face_count += 1
    var saturated = InlineArray[Bool, MAX_EDGES](fill=False)
    for edge in (triangle.e0, triangle.e1, triangle.e2):
        incidence[edge] -= 1
        used[edge] += 1
        if used[edge] == 2:
            saturated[edge] = True
    for other in range(triangle_count):
        if not triangles[other].active:
            continue
        let candidate = triangles[other]
        if saturated[candidate.e0] or saturated[candidate.e1] or saturated[candidate.e2]:
            triangles[other].active = False
            incidence[candidate.e0] -= 1
            incidence[candidate.e1] -= 1
            incidence[candidate.e2] -= 1

fn face_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("triangle_mesh_faces_from_edge_graph")
fn triangle_mesh_faces_from_edge_graph(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_WORDS):
        return -1
    let vertex_word = input[0]
    let edge_word = input[1]
    if vertex_word < 3 or vertex_word > MAX_VERTICES or edge_word < 0 or edge_word > MAX_EDGES:
        return -1
    let vertices = Int(vertex_word)
    let edge_count = Int(edge_word)
    if edge_count > vertices * (vertices - 1) // 2 or length != c_size_t(2 + 2 * edge_count):
        return -1

    var edge_index = InlineArray[InlineArray[Int, MAX_VERTICES], MAX_VERTICES]()
    for a in range(MAX_VERTICES):
        for b in range(MAX_VERTICES):
            edge_index[a][b] = -1
    var vertex_degree = InlineArray[Int, MAX_VERTICES](fill=0)
    for edge in range(edge_count):
        let left_word = input[2 + 2 * edge]
        let right_word = input[3 + 2 * edge]
        if left_word < 0 or left_word >= vertex_word or right_word < 0 or right_word >= vertex_word or left_word == right_word:
            return -1
        var left = Int(left_word)
        var right = Int(right_word)
        if left > right:
            let swap = left
            left = right
            right = swap
        if edge_index[left][right] >= 0:
            return -1
        edge_index[left][right] = edge
        edge_index[right][left] = edge
        vertex_degree[left] += 1
        vertex_degree[right] += 1

    var triangles = InlineArray[FaceTriangle, MAX_TRIANGLES]()
    var triangle_count = 0
    var incidence = InlineArray[Int, MAX_EDGES](fill=0)
    for a in range(vertices):
        for b in range(a + 1, vertices):
            for c in range(b + 1, vertices):
                let e0 = edge_index[a][b]
                let e1 = edge_index[a][c]
                let e2 = edge_index[b][c]
                if e0 >= 0 and e1 >= 0 and e2 >= 0:
                    triangles[triangle_count] = FaceTriangle(a, b, c, e0, e1, e2, True)
                    triangle_count += 1
                    incidence[e0] += 1
                    incidence[e1] += 1
                    incidence[e2] += 1

    var used = InlineArray[Int, MAX_EDGES](fill=0)
    var staged = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    var face_count = 0
    var fallback_used = False
    while True:
        var chosen = triangle_count
        for index in range(triangle_count):
            let triangle = triangles[index]
            if triangle.active and (vertex_degree[triangle.a] == 3 or vertex_degree[triangle.b] == 3 or vertex_degree[triangle.c] == 3):
                chosen = index
                break
        if chosen < triangle_count:
            face_select(chosen, triangles, triangle_count, incidence, used, staged, face_count)
            continue

        var forced = InlineArray[Bool, MAX_EDGES](fill=False)
        for edge in range(edge_count):
            forced[edge] = incidence[edge] > 0 and incidence[edge] == 2 - used[edge]
        chosen = triangle_count
        for index in range(triangle_count):
            let triangle = triangles[index]
            if triangle.active and (forced[triangle.e0] or forced[triangle.e1] or forced[triangle.e2]):
                chosen = index
                break
        if chosen < triangle_count:
            face_select(chosen, triangles, triangle_count, incidence, used, staged, face_count)
            continue

        var best_score = 3 * MAX_TRIANGLES + 1
        chosen = triangle_count
        for index in range(triangle_count):
            let triangle = triangles[index]
            if not triangle.active:
                continue
            let score = incidence[triangle.e0] + incidence[triangle.e1] + incidence[triangle.e2]
            if score < best_score:
                best_score = score
                chosen = index
        if chosen == triangle_count:
            break
        fallback_used = True
        face_select(chosen, triangles, triangle_count, incidence, used, staged, face_count)

    var complete = edge_count > 0
    for edge in range(edge_count):
        if used[edge] != 2:
            complete = False
    staged[0] = (0 if complete else 2) + (1 if fallback_used else 0)
    staged[1] = Int64(face_count)
    let output_bytes = (2 + 3 * face_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for word in range(2 + 3 * face_count):
        face_store_i64_le(output, word * 8, staged[word])
    return Int64(output_bytes)
