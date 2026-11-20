from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_ISLANDS: Int = 6
comptime MAX_EDGE_SLOTS: Int = 12
comptime MAX_PARSEABLE_INPUT_LENGTH: Int = 20

struct HashiSolver:
    var island_count: Int
    var edge_count: Int
    var x: InlineArray[Int64, 6]
    var y: InlineArray[Int64, 6]
    var residual: InlineArray[Int64, 6]
    var remaining: InlineArray[Int, 6]
    var edge_u: InlineArray[Int, 12]
    var edge_v: InlineArray[Int, 12]
    var multiplicity: InlineArray[Int, 12]
    var solution: InlineArray[Int, 12]

    fn __init__(out self):
        self.island_count = 0
        self.edge_count = 0
        self.x = InlineArray[Int64, 6](fill=0)
        self.y = InlineArray[Int64, 6](fill=0)
        self.residual = InlineArray[Int64, 6](fill=0)
        self.remaining = InlineArray[Int, 6](fill=0)
        self.edge_u = InlineArray[Int, 12](fill=0)
        self.edge_v = InlineArray[Int, 12](fill=0)
        self.multiplicity = InlineArray[Int, 12](fill=0)
        self.solution = InlineArray[Int, 12](fill=0)

fn hashi_edges_cross(
    x: InlineArray[Int64, 6],
    y: InlineArray[Int64, 6],
    edge_u: InlineArray[Int, 12],
    edge_v: InlineArray[Int, 12],
    first: Int,
    second: Int,
) -> Bool:
    let a = edge_u[first]
    let b = edge_v[first]
    let c = edge_u[second]
    let d = edge_v[second]
    let first_horizontal = y[a] == y[b]
    let second_horizontal = y[c] == y[d]
    if first_horizontal == second_horizontal:
        return False
    var h0 = a
    var h1 = b
    var v0 = c
    var v1 = d
    if not first_horizontal:
        h0 = c
        h1 = d
        v0 = a
        v1 = b
    let hx = x[v0]
    let hy = y[h0]
    let hmin = min(x[h0], x[h1])
    let hmax = max(x[h0], x[h1])
    let vmin = min(y[v0], y[v1])
    let vmax = max(y[v0], y[v1])
    return hmin < hx and hx < hmax and vmin < hy and hy < vmax

fn hashi_possible_graph_connected(s: HashiSolver, assigned_through: Int) -> Bool:
    var reached = InlineArray[Bool, 6](fill=False)
    var stack = InlineArray[Int, 6](fill=0)
    var top = 1
    reached[0] = True
    stack[0] = 0
    while top != 0:
        top -= 1
        let island = stack[top]
        for edge in range(s.edge_count):
            var usable = edge <= assigned_through and s.multiplicity[edge] != 0
            if edge > assigned_through:
                usable = True
                for fixed in range(assigned_through + 1):
                    if s.multiplicity[fixed] != 0 and hashi_edges_cross(
                            s.x, s.y, s.edge_u, s.edge_v, fixed, edge):
                        usable = False
                        break
            if not usable:
                continue
            var neighbor = s.island_count
            if s.edge_u[edge] == island:
                neighbor = s.edge_v[edge]
            elif s.edge_v[edge] == island:
                neighbor = s.edge_u[edge]
            if neighbor < s.island_count and not reached[neighbor]:
                reached[neighbor] = True
                stack[top] = neighbor
                top += 1
    for island in range(s.island_count):
        if not reached[island]:
            return False
    return True

fn hashi_residuals_feasible(s: HashiSolver) -> Bool:
    for island in range(s.island_count):
        if s.residual[island] < 0 or s.residual[island] > 2 * s.remaining[island]:
            return False
    return True

fn hashi_search(inout s: HashiSolver, depth: Int) -> Bool:
    if depth == s.edge_count:
        for island in range(s.island_count):
            if s.residual[island] != 0:
                return False
        if not hashi_possible_graph_connected(s, s.edge_count - 1):
            return False
        for edge in range(s.edge_count):
            s.solution[edge] = s.multiplicity[edge]
        return True

    let u = s.edge_u[depth]
    let v = s.edge_v[depth]
    s.remaining[u] -= 1
    s.remaining[v] -= 1
    for amount in range(3):
        if Int64(amount) > s.residual[u] or Int64(amount) > s.residual[v]:
            continue
        var conflict = False
        if amount != 0:
            for prior in range(depth):
                if s.multiplicity[prior] != 0 and hashi_edges_cross(
                        s.x, s.y, s.edge_u, s.edge_v, prior, depth):
                    conflict = True
                    break
        if conflict:
            continue
        s.multiplicity[depth] = amount
        s.residual[u] -= Int64(amount)
        s.residual[v] -= Int64(amount)
        if hashi_residuals_feasible(s) and hashi_possible_graph_connected(s, depth) and
            hashi_search(inout s, depth + 1):
            s.residual[u] += Int64(amount)
            s.residual[v] += Int64(amount)
            s.remaining[u] += 1
            s.remaining[v] += 1
            return True
        s.residual[u] += Int64(amount)
        s.residual[v] += Int64(amount)
        s.multiplicity[depth] = 0
    s.remaining[u] += 1
    s.remaining[v] += 1
    return False

@export("hashiwokakero_small_solver")
fn hashiwokakero_small_solver(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    input_length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
        input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if input[0] < 2 or input[0] > MAX_ISLANDS:
        return -1
    let island_count = Int(input[0])
    if input_length != c_size_t(1 + 3 * island_count):
        return -1
    var s = HashiSolver()
    s.island_count = island_count
    for island in range(island_count):
        let x = input[1 + 3 * island]
        let y = input[2 + 3 * island]
        let demand = input[3 + 3 * island]
        if x < 0 or x > 7 or y < 0 or y > 7 or demand < 1 or demand > 8:
            return -1
        for prior in range(island):
            if s.x[prior] == x and s.y[prior] == y:
                return -1
        s.x[island] = x
        s.y[island] = y
        s.residual[island] = demand

    for first in range(island_count):
        for second in range(first + 1, island_count):
            if s.x[first] != s.x[second] and s.y[first] != s.y[second]:
                continue
            var blocked = False
            for middle in range(island_count):
                if middle == first or middle == second:
                    continue
                if s.y[first] == s.y[second] and s.y[middle] == s.y[first] and
                    min(s.x[first], s.x[second]) < s.x[middle] and
                    s.x[middle] < max(s.x[first], s.x[second]):
                    blocked = True
                if s.x[first] == s.x[second] and s.x[middle] == s.x[first] and
                    min(s.y[first], s.y[second]) < s.y[middle] and
                    s.y[middle] < max(s.y[first], s.y[second]):
                    blocked = True
            if not blocked:
                if s.edge_count == MAX_EDGE_SLOTS:
                    return -1
                let edge = s.edge_count
                s.edge_count += 1
                s.edge_u[edge] = first
                s.edge_v[edge] = second
                s.remaining[first] += 1
                s.remaining[second] += 1

    if not hashi_search(inout s, 0):
        return -2
    var result: Int64 = Int64(1) << 32
    for edge in range(s.edge_count):
        result |= Int64(s.solution[edge]) << (2 * edge)
    return result
