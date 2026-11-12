from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_POINTS = 8
comptime MAX_EDGES = MAX_POINTS * (MAX_POINTS - 1) // 2
comptime MAX_INPUT_LENGTH = 18
comptime MAX_OUTPUT_WORDS = 2 * MAX_POINTS - 1

struct Point:
    var x: Int64
    var y: Int64

    fn __init__(out self, x: Int64, y: Int64):
        self.x = x
        self.y = y

struct Edge:
    var u: Int
    var v: Int
    var weight: Int64

    fn __init__(out self, u: Int, v: Int, weight: Int64):
        self.u = u
        self.v = v
        self.weight = weight

fn orientation(a: Point, b: Point, c: Point) -> Int64:
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

fn incircle(a: Point, b: Point, c: Point, d: Point) -> Int64:
    let ax=a.x-d.x; let ay=a.y-d.y; let bx=b.x-d.x; let by=b.y-d.y; let cx=c.x-d.x; let cy=c.y-d.y
    return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx) + (cx*cx+cy*cy)*(ax*by-ay*bx)

fn general_position(points: InlineArray[Point, MAX_POINTS], n: Int) -> Bool:
    for a in range(n):
        for b in range(a + 1, n):
            if points[a].x == points[b].x and points[a].y == points[b].y:
                return False
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                if orientation(points[a], points[b], points[c]) == 0:
                    return False
                for d in range(n):
                    if d != a and d != b and d != c and incircle(points[a], points[b], points[c], points[d]) == 0:
                        return False
    return True

fn find_root(mut parent: InlineArray[Int, MAX_POINTS], vertex: Int) -> Int:
    var current = vertex
    while parent[current] != current:
        parent[current] = parent[parent[current]]
        current = parent[current]
    return current

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("euclidean_mst")
fn euclidean_mst(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_n = input[0]
    if raw_n < 1 or raw_n > MAX_POINTS:
        return -1
    let n = Int(raw_n)
    if length != c_size_t(1 + 2 * n):
        return -1
    var points = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
    for i in range(n):
        points[i] = Point(input[1 + 2 * i], input[2 + 2 * i])
        if points[i].x < -10 or points[i].x > 10 or points[i].y < -10 or points[i].y > 10:
            return -1
    if not general_position(points, n):
        return -1
    let output_words = 2 * n - 1
    let output_bytes = 8 * output_words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2

    var candidates = InlineArray[Int, MAX_POINTS * MAX_POINTS](fill=0)
    if n == 2: candidates[1] = 1; candidates[MAX_POINTS] = 1
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                let turn = orientation(points[a], points[b], points[c])
                var empty = True
                for d in range(n):
                    if d == a or d == b or d == c:
                        continue
                    let determinant = incircle(points[a], points[b], points[c], points[d])
                    if (determinant > 0) == (turn > 0):
                        empty = False
                        break
                if empty:
                    candidates[a * MAX_POINTS + b] = 1
                    candidates[b * MAX_POINTS + a] = 1
                    candidates[a * MAX_POINTS + c] = 1
                    candidates[c * MAX_POINTS + a] = 1
                    candidates[b * MAX_POINTS + c] = 1
                    candidates[c * MAX_POINTS + b] = 1

    var edges = InlineArray[Edge, MAX_EDGES](fill=Edge(0, 0, 0))
    var edge_count = 0
    for u in range(n):
        for v in range(u + 1, n):
            if candidates[u * MAX_POINTS + v] == 0:
                continue
            let dx = points[u].x - points[v].x
            let dy = points[u].y - points[v].y
            let edge = Edge(u, v, dx * dx + dy * dy)
            var position = edge_count
            edge_count += 1
            while position > 0:
                let previous = edges[position - 1]
                if previous.weight < edge.weight or (previous.weight == edge.weight and
                    (previous.u < edge.u or (previous.u == edge.u and previous.v <= edge.v))):
                    break
                edges[position] = previous
                position -= 1
            edges[position] = edge

    var parent = InlineArray[Int, MAX_POINTS](fill=0)
    var sizes = InlineArray[Int, MAX_POINTS](fill=0)
    for i in range(n):
        parent[i] = i
        sizes[i] = 1
    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    words[0] = Int64(n - 1)
    var selected = 0
    for i in range(edge_count):
        if selected == n - 1:
            break
        var left = find_root(mut parent, edges[i].u)
        var right = find_root(mut parent, edges[i].v)
        if left == right:
            continue
        if sizes[left] < sizes[right]:
            let temporary = left
            left = right
            right = temporary
        parent[right] = left
        sizes[left] += sizes[right]
        words[1 + 2 * selected] = Int64(edges[i].u)
        words[2 + 2 * selected] = Int64(edges[i].v)
        selected += 1
    if selected != n - 1:
        return -1
    for word in range(output_words):
        store_i64_le(output, 8 * word, words[word])
    return Int64(output_bytes)
