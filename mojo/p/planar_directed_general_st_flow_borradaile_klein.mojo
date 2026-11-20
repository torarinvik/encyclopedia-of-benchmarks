from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PDF_N = 6
comptime PDF_M = 10
comptime PDF_D = 20
comptime PDF_F = 10
comptime PDF_MAX_INPUT = 61
comptime PDF_MAX_AUG = 25
comptime PDF_INF: Int64 = 0x3fffffffffffffff

struct PdfGraph(Copyable):
    var n: Int
    var m: Int
    var source: Int
    var sink: Int
    var tail: InlineArray[Int, PDF_M]
    var head: InlineArray[Int, PDF_M]
    var capacity: InlineArray[Int, PDF_M]
    var degree: InlineArray[Int, PDF_N]
    var rotation: InlineArray[Int, PDF_N * PDF_N]
    var local_position: InlineArray[Int, PDF_N * PDF_M]
    var left_face: InlineArray[Int, PDF_D]
    var right_face: InlineArray[Int, PDF_D]
    var faces: Int
    var infinity_face: Int
    var root_anchor: Int

    fn __init__(out self):
        self.n = 0
        self.m = 0
        self.source = 0
        self.sink = 0
        self.tail = InlineArray[Int, PDF_M](fill=0)
        self.head = InlineArray[Int, PDF_M](fill=0)
        self.capacity = InlineArray[Int, PDF_M](fill=0)
        self.degree = InlineArray[Int, PDF_N](fill=0)
        self.rotation = InlineArray[Int, PDF_N * PDF_N](fill=0)
        self.local_position = InlineArray[Int, PDF_N * PDF_M](fill=-1)
        self.left_face = InlineArray[Int, PDF_D](fill=0)
        self.right_face = InlineArray[Int, PDF_D](fill=0)
        self.faces = 0
        self.infinity_face = 0
        self.root_anchor = 0

fn pdf_dart_head(g: PdfGraph, dart: Int) -> Int:
    let e = dart // 2
    return g.head[e] if dart % 2 == 0 else g.tail[e]

fn pdf_left_successor(g: PdfGraph, dart: Int) -> Int:
    let vertex = pdf_dart_head(g, dart)
    let edge = dart // 2
    let degree = g.degree[vertex]
    let position = g.local_position[vertex * PDF_M + edge]
    if degree <= 0 or position < 0: return -1
    let prior = g.rotation[vertex * PDF_N + (position + degree - 1) % degree]
    return 2 * prior + (1 if g.head[prior] == vertex else 0)

fn pdf_decode(input: view[Int64], inout g: PdfGraph) -> Bool:
    if len(input) < 4 or len(input) > PDF_MAX_INPUT: return False
    let n0 = input[0]
    let m0 = input[1]
    let s0 = input[2]
    let t0 = input[3]
    if n0 < 2 or n0 > PDF_N or m0 < 1 or m0 > PDF_M or s0 < 0 or s0 >= n0 or t0 < 0 or t0 >= n0 or s0 == t0: return False
    g.n = Int(n0)
    g.m = Int(m0)
    g.source = Int(s0)
    g.sink = Int(t0)
    if len(input) < 4 + 3 * g.m: return False
    var pairs = InlineArray[Bool, PDF_N * PDF_N](fill=False)
    var occurrence = InlineArray[Int, PDF_M * 2](fill=0)
    var used = InlineArray[Bool, PDF_N * PDF_M](fill=False)
    var at = 4
    for edge in range(g.m):
        let u0 = input[at]
        let v0 = input[at + 1]
        let cap0 = input[at + 2]
        at += 3
        if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or cap0 < 1 or cap0 > 5: return False
        let u = Int(u0)
        let v = Int(v0)
        if pairs[u * PDF_N + v] or pairs[v * PDF_N + u]: return False
        pairs[u * PDF_N + v] = True
        pairs[v * PDF_N + u] = True
        g.tail[edge] = u
        g.head[edge] = v
        g.capacity[edge] = Int(cap0)
    for vertex in range(g.n):
        let degree0 = input[at]
        at += 1
        if degree0 < 1 or degree0 >= n0 or at + Int(degree0) > len(input): return False
        g.degree[vertex] = Int(degree0)
        for j in range(Int(degree0)):
            let edge0 = input[at]
            at += 1
            if edge0 < 0 or edge0 >= m0: return False
            let edge = Int(edge0)
            let slot = vertex * PDF_M + edge
            if used[slot]: return False
            used[slot] = True
            g.rotation[vertex * PDF_N + j] = edge
            g.local_position[slot] = j
            if g.tail[edge] == vertex:
                occurrence[2 * edge] += 1
            elif g.head[edge] == vertex:
                occurrence[2 * edge + 1] += 1
            else:
                return False
    if at != len(input): return False
    for edge in range(g.m):
        if occurrence[2 * edge] != 1 or occurrence[2 * edge + 1] != 1: return False

    var adjacent = InlineArray[Bool, PDF_N * PDF_N](fill=False)
    for edge in range(g.m):
        let u = g.tail[edge]
        let v = g.head[edge]
        adjacent[u * PDF_N + v] = True
        adjacent[v * PDF_N + u] = True
    var reached = InlineArray[Bool, PDF_N](fill=False)
    var queue = InlineArray[Int, PDF_N](fill=0)
    var qh = 0
    var qt = 1
    reached[g.source] = True
    queue[0] = g.source
    while qh < qt:
        let vertex = queue[qh]
        qh += 1
        for neighbor in range(g.n):
            if adjacent[vertex * PDF_N + neighbor] and not reached[neighbor]:
                reached[neighbor] = True
                queue[qt] = neighbor
                qt += 1
    for vertex in range(g.n):
        if not reached[vertex]: return False

    var face_of = InlineArray[Int, PDF_D](fill=-1)
    g.faces = 0
    for start in range(2 * g.m):
        if face_of[start] >= 0: continue
        var dart = start
        while face_of[dart] < 0:
            face_of[dart] = g.faces
            dart = pdf_left_successor(g, dart)
            if dart < 0: return False
        if dart != start: return False
        g.faces += 1
    if g.faces != g.m - g.n + 2: return False
    for dart in range(2 * g.m):
        g.left_face[dart] = face_of[dart]
        g.right_face[dart] = face_of[dart ^ 1]
    g.root_anchor = g.rotation[g.sink * PDF_N]
    let root_dart = 2 * g.root_anchor + (1 if g.head[g.root_anchor] == g.sink else 0)
    g.infinity_face = g.right_face[root_dart]
    return True

fn pdf_visit(inout g: PdfGraph, vertex: Int, anchor: Int, root: Bool,
    residual: view[Int], inout seen: InlineArray[Bool, PDF_N], inout parent: InlineArray[Int, PDF_N]):
    let degree = g.degree[vertex]
    let position = g.local_position[vertex * PDF_M + anchor]
    let first = 0 if root else 1
    for step in range(first, first + degree):
        let edge = g.rotation[vertex * PDF_N + (position + step) % degree]
        let neighbor = g.head[edge] if g.tail[edge] == vertex else g.tail[edge]
        if not seen[neighbor] and residual[neighbor * PDF_N + vertex] > 0:
            seen[neighbor] = True
            parent[neighbor] = vertex
            pdf_visit(inout g, neighbor, edge, False, residual, inout seen, inout parent)

fn pdf_solve(inout g: PdfGraph) -> Int64:
    var dual = InlineArray[Int64, PDF_F * PDF_F](fill=PDF_INF)
    var distance = InlineArray[Int64, PDF_F](fill=PDF_INF)
    var settled = InlineArray[Bool, PDF_F](fill=False)
    for dart in range(2 * g.m):
        let from = g.right_face[dart]
        let to = g.left_face[dart]
        let weight = Int64(g.capacity[dart // 2]) if dart % 2 == 0 else Int64(0)
        let slot = from * PDF_F + to
        if weight < dual[slot]: dual[slot] = weight
    distance[g.infinity_face] = 0
    for _ in range(g.faces):
        var current = -1
        for face in range(g.faces):
            if not settled[face] and (current < 0 or distance[face] < distance[current]): current = face
        if current < 0 or distance[current] == PDF_INF: break
        settled[current] = True
        for next in range(g.faces):
            let weight = dual[current * PDF_F + next]
            if weight != PDF_INF and distance[current] + weight < distance[next]: distance[next] = distance[current] + weight
    var residual = InlineArray[Int, PDF_N * PDF_N](fill=0)
    for edge in range(g.m):
        let eta = distance[g.left_face[2 * edge]] - distance[g.right_face[2 * edge]]
        if eta < 0 or eta > g.capacity[edge]: return -1
        let u = g.tail[edge]
        let v = g.head[edge]
        residual[u * PDF_N + v] += g.capacity[edge] - Int(eta)
        residual[v * PDF_N + u] += Int(eta)
    var total: Int64 = 0
    for augmentation in range(PDF_MAX_AUG + 1):
        var seen = InlineArray[Bool, PDF_N](fill=False)
        var parent = InlineArray[Int, PDF_N](fill=-1)
        seen[g.sink] = True
        pdf_visit(inout g, g.sink, g.root_anchor, True, residual[0:PDF_N * PDF_N], inout seen, inout parent)
        if not seen[g.source]: return total
        if augmentation == PDF_MAX_AUG: return -1
        var delta = 0x7fffffff
        var vertex = g.source
        while vertex != g.sink:
            let next = parent[vertex]
            delta = min(delta, residual[vertex * PDF_N + next])
            vertex = next
        vertex = g.source
        while vertex != g.sink:
            let next = parent[vertex]
            residual[vertex * PDF_N + next] -= delta
            residual[next * PDF_N + vertex] += delta
            vertex = next
        total += Int64(delta)
    return -1

@export("planar_directed_general_st_flow_borradaile_klein")
fn planar_directed_general_st_flow_borradaile_klein(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > PDF_MAX_INPUT: return -1
    var graph = PdfGraph()
    let input_view: view[Int64] = input[0:Int(length)]
    if not pdf_decode(input_view, inout graph): return -1
    let value = pdf_solve(inout graph)
    if value < 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bytes = InlineArray[UInt8, 8](fill=0)
    let bits = UInt64(value)
    for i in range(8): bytes[i] = UInt8((bits >> (8 * i)) & 255)
    for i in range(8): output[i] = bytes[i]
    return 8
