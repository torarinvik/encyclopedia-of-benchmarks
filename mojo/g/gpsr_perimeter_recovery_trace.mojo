from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn gpsr_cross(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Int64:
    ax * by - ay * bx

fn gpsr_orient(xs: InlineArray[Int64, 8], ys: InlineArray[Int64, 8],
               a: Int, b: Int, c: Int) -> Int64:
    gpsr_cross(xs[b] - xs[a], ys[b] - ys[a], xs[c] - xs[a], ys[c] - ys[a])

fn gpsr_half(x: Int64, y: Int64) -> Int:
    if y > 0 or (y == 0 and x >= 0): return 0
    1

fn gpsr_angle_less(ax: Int64, ay: Int64, ai: Int, bx: Int64, by: Int64, bi: Int) -> Bool:
    let ah = gpsr_half(ax, ay)
    let bh = gpsr_half(bx, by)
    if ah != bh: return ah < bh
    let turn = gpsr_cross(ax, ay, bx, by)
    if turn != 0: return turn > 0
    ai < bi

fn gpsr_segments_cross(xs: InlineArray[Int64, 8], ys: InlineArray[Int64, 8],
                       a: Int, b: Int, c: Int, d: Int) -> Bool:
    gpsr_orient(xs, ys, a, b, c) * gpsr_orient(xs, ys, a, b, d) < 0 and
        gpsr_orient(xs, ys, c, d, a) * gpsr_orient(xs, ys, c, d, b) < 0

fn gpsr_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = a0
    var b = b0
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    a

fn gpsr_proper_crossing(px: Int64, py: Int64, qx: Int64, qy: Int64,
                        ax: Int64, ay: Int64, bx: Int64, by: Int64,
                        mut numerator: Int64, mut denominator: Int64) -> Bool:
    let rx = qx - px
    let ry = qy - py
    let sx = bx - ax
    let sy = by - ay
    var den = gpsr_cross(rx, ry, sx, sy)
    if den == 0: return False
    let ox = ax - px
    let oy = ay - py
    var tn = gpsr_cross(ox, oy, sx, sy)
    var un = gpsr_cross(ox, oy, rx, ry)
    if den < 0:
        den = -den
        tn = -tn
        un = -un
    if not (tn > 0 and tn < den and un > 0 and un < den): return False
    let divisor = gpsr_gcd(tn, den)
    numerator = tn // divisor
    denominator = den // divisor
    True

fn gpsr_next_ccw(node: Int, incoming: Int,
                 degree: InlineArray[Int, 8],
                 rotation: InlineArray[Int, 64]) -> Int:
    for i in range(degree[node]):
        if rotation[node * 8 + i] == incoming:
            return rotation[node * 8 + ((i + 1) % degree[node])]
    -1

fn gpsr_edge_id(u0: Int, v0: Int, m: Int,
                edge_u: InlineArray[Int, 18], edge_v: InlineArray[Int, 18]) -> Int:
    let lo = min(u0, v0)
    let hi = max(u0, v0)
    for i in range(m):
        if edge_u[i] == lo and edge_v[i] == hi: return i
    -1

fn gpsr_put64(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[position + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("gpsr_perimeter_recovery_trace")
fn gpsr_perimeter_recovery_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 57:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    let source64 = input[2]
    let target64 = input[3]
    if (n64 < 3 or n64 > 8 or m64 < n64 - 1 or m64 > 18 or
        m64 > 3 * n64 - 6 or source64 < 0 or target64 < 0 or
        source64 >= n64 or target64 >= n64 or source64 == target64):
        return -1
    let n = Int(n64)
    let m = Int(m64)
    let source = Int(source64)
    let target = Int(target64)
    if Int64(length) != Int64(4 + 2 * n + 2 * m): return -1

    var xs = InlineArray[Int64, 8](fill=0)
    var ys = InlineArray[Int64, 8](fill=0)
    for i in range(n):
        xs[i] = input[4 + i]
        ys[i] = input[4 + n + i]
        if xs[i] < -16 or xs[i] > 16 or ys[i] < -16 or ys[i] > 16: return -1
        for j in range(i):
            if xs[i] == xs[j] and ys[i] == ys[j]: return -1
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if gpsr_orient(xs, ys, i, j, k) == 0: return -1

    var degree = InlineArray[Int, 8](fill=0)
    var adjacency = InlineArray[Int, 64](fill=0)
    var rotation = InlineArray[Int, 64](fill=0)
    var edge_u = InlineArray[Int, 18](fill=0)
    var edge_v = InlineArray[Int, 18](fill=0)
    let edge_start = 4 + 2 * n
    for i in range(m):
        let u64 = input[edge_start + 2 * i]
        let v64 = input[edge_start + 2 * i + 1]
        if u64 < 0 or v64 >= n64 or u64 >= v64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if i > 0 and (edge_u[i - 1] > u or
            (edge_u[i - 1] == u and edge_v[i - 1] >= v)): return -1
        edge_u[i] = u
        edge_v[i] = v
        adjacency[u * 8 + degree[u]] = v
        adjacency[v * 8 + degree[v]] = u
        degree[u] += 1
        degree[v] += 1

    var reached = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    reached[source] = True
    queue[0] = source
    while head < tail:
        let u = queue[head]
        head += 1
        for i in range(degree[u]):
            let v = adjacency[u * 8 + i]
            if not reached[v]:
                reached[v] = True
                queue[tail] = v
                tail += 1
    for i in range(n):
        if not reached[i]: return -1

    for i in range(m):
        for j in range(i + 1, m):
            let a = edge_u[i]
            let b = edge_v[i]
            let c = edge_u[j]
            let d = edge_v[j]
            if a != c and a != d and b != c and b != d and
                gpsr_segments_cross(xs, ys, a, b, c, d): return -1

    let sx = xs[source] - xs[target]
    let sy = ys[source] - ys[target]
    let source_distance = sx * sx + sy * sy
    for i in range(degree[source]):
        let v = adjacency[source * 8 + i]
        let dx = xs[v] - xs[target]
        let dy = ys[v] - ys[target]
        if dx * dx + dy * dy < source_distance: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 896: return -2

    for u in range(n):
        for i in range(degree[u]): rotation[u * 8 + i] = adjacency[u * 8 + i]
        for i in range(1, degree[u]):
            let v = rotation[u * 8 + i]
            let dx = xs[v] - xs[u]
            let dy = ys[v] - ys[u]
            var j = i
            while j > 0:
                let w = rotation[u * 8 + j - 1]
                if not gpsr_angle_less(dx, dy, v, xs[w] - xs[u], ys[w] - ys[u], w): break
                rotation[u * 8 + j] = w
                j -= 1
            rotation[u * 8 + j] = v

    var path = InlineArray[Int, 37](fill=0)
    var events = InlineArray[Int64, 72](fill=0)
    var path_count = 1
    var crossing_count = 0
    var current = source
    var previous = -1
    var e0u = -1
    var e0v = -1
    var lf_num: Int64 = 0
    var lf_den: Int64 = 1
    var status: Int64 = 0
    path[0] = source

    while True:
        let dx = xs[current] - xs[target]
        let dy = ys[current] - ys[target]
        if current == target:
            status = 2
            break
        if dx * dx + dy * dy < source_distance:
            status = 1
            break
        if path_count - 1 >= 2 * m:
            status = 0
            break
        var candidate = -1
        if previous < 0:
            let rx = xs[target] - xs[current]
            let ry = ys[target] - ys[current]
            var best_x: Int64 = 0
            var best_y: Int64 = 0
            for i in range(degree[current]):
                let v = adjacency[current * 8 + i]
                let vx = rx * (xs[v] - xs[current]) + ry * (ys[v] - ys[current])
                let vy = gpsr_cross(rx, ry, xs[v] - xs[current], ys[v] - ys[current])
                if candidate < 0 or gpsr_angle_less(vx, vy, v, best_x, best_y, candidate):
                    candidate = v
                    best_x = vx
                    best_y = vy
        else:
            candidate = gpsr_next_ccw(current, previous, degree, rotation)
        if candidate < 0:
            status = 0
            break
        var changed_face = False
        var invalid_state = False
        while True:
            var t_num: Int64 = 0
            var t_den: Int64 = 1
            if not gpsr_proper_crossing(
                xs[source], ys[source], xs[target], ys[target],
                xs[current], ys[current], xs[candidate], ys[candidate], t_num, t_den
            ) or t_num * lf_den <= lf_num * t_den:
                break
            let id = gpsr_edge_id(current, candidate, m, edge_u, edge_v)
            if id < 0 or crossing_count >= 18:
                status = 0
                invalid_state = True
                break
            let event_at = crossing_count * 4
            events[event_at] = Int64(path_count - 1)
            events[event_at + 1] = Int64(id)
            events[event_at + 2] = t_num
            events[event_at + 3] = t_den
            crossing_count += 1
            lf_num = t_num
            lf_den = t_den
            changed_face = True
            candidate = gpsr_next_ccw(current, candidate, degree, rotation)
            if candidate < 0:
                status = 0
                invalid_state = True
                break
        if invalid_state: break
        if changed_face or e0u < 0:
            e0u = current
            e0v = candidate
        elif e0u == current and e0v == candidate:
            status = 0
            break
        previous = current
        current = candidate
        if path_count >= 37:
            status = 0
            break
        path[path_count] = current
        path_count += 1

    var words = InlineArray[Int64, 112](fill=0)
    var word_count = 0
    words[word_count] = status
    word_count += 1
    words[word_count] = Int64(path_count - 1)
    word_count += 1
    for i in range(path_count):
        words[word_count] = Int64(path[i])
        word_count += 1
    words[word_count] = Int64(crossing_count)
    word_count += 1
    for i in range(crossing_count * 4):
        words[word_count] = events[i]
        word_count += 1
    for i in range(word_count): gpsr_put64(output, 8 * i, words[i])
    Int64(8 * word_count)
