from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias MAX_M = 42
alias MAX_INPUT = 118
alias MAX_COORD = 100

fn pfc_orient(points: InlineArray[Int64, 32], a: Int, b: Int, c: Int) -> Int64:
    return (points[2*b] - points[2*a]) * (points[2*c + 1] - points[2*a + 1]) - (
        points[2*b + 1] - points[2*a + 1]
    ) * (points[2*c] - points[2*a])

fn pfc_between(a: Int64, b: Int64, p: Int64) -> Bool:
    return (a <= p and p <= b) or (b <= p and p <= a)

fn pfc_on_segment(points: InlineArray[Int64, 32], a: Int, b: Int, p: Int) -> Bool:
    return pfc_between(points[2*a], points[2*b], points[2*p]) and pfc_between(
        points[2*a + 1], points[2*b + 1], points[2*p + 1]
    )

fn pfc_intersects(points: InlineArray[Int64, 32], a: Int, b: Int, c: Int, d: Int) -> Bool:
    let ab_c = pfc_orient(points, a, b, c)
    let ab_d = pfc_orient(points, a, b, d)
    let cd_a = pfc_orient(points, c, d, a)
    let cd_b = pfc_orient(points, c, d, b)
    if (((ab_c > 0 and ab_d < 0) or (ab_c < 0 and ab_d > 0)) and
        ((cd_a > 0 and cd_b < 0) or (cd_a < 0 and cd_b > 0))):
        return True
    return (ab_c == 0 and pfc_on_segment(points, a, b, c)) or (
        ab_d == 0 and pfc_on_segment(points, a, b, d)
    ) or (cd_a == 0 and pfc_on_segment(points, c, d, a)) or (
        cd_b == 0 and pfc_on_segment(points, c, d, b)
    )

fn pfc_half(dx: Int64, dy: Int64) -> Int:
    if dy > 0 or (dy == 0 and dx >= 0):
        return 0
    return 1

fn pfc_angle_less(a: Int, b: Int, origin: Int, points: InlineArray[Int64, 32]) -> Bool:
    let ax = points[2*a] - points[2*origin]
    let ay = points[2*a + 1] - points[2*origin + 1]
    let bx = points[2*b] - points[2*origin]
    let by = points[2*b + 1] - points[2*origin + 1]
    let ah = pfc_half(ax, ay)
    let bh = pfc_half(bx, by)
    return ah < bh or (ah == bh and ax * by - ay * bx > 0)

@export("planar_face_count")
fn planar_face_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_M:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    let edge_cap = if n == 1: 0 elif n == 2: 1 else: 3 * n - 6
    if m > edge_cap or length != c_size_t(2 + 2 * n + 2 * m):
        return -1

    var points = InlineArray[Int64, 32]()
    for v in range(n):
        points[2 * v] = input[2 + 2 * v]
        points[2 * v + 1] = input[3 + 2 * v]
        if points[2 * v] < -MAX_COORD or points[2 * v] > MAX_COORD or (
            points[2 * v + 1] < -MAX_COORD or points[2 * v + 1] > MAX_COORD
        ):
            return -1
        for prior in range(v):
            if points[2 * v] == points[2 * prior] and points[2 * v + 1] == points[2 * prior + 1]:
                return -1

    var adjacent = InlineArray[Bool, MAX_N * MAX_N]()
    var neighbors = InlineArray[Int, MAX_N * MAX_N]()
    var degree = InlineArray[Int, MAX_N]()
    var edge_u = InlineArray[Int, MAX_M]()
    var edge_v = InlineArray[Int, MAX_M]()
    let offset = 2 + 2 * n
    for e in range(m):
        let u_value = input[offset + 2 * e]
        let v_value = input[offset + 2 * e + 1]
        if u_value < 0 or u_value >= n or v_value < 0 or v_value >= n or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if adjacent[u * MAX_N + v]:
            return -1
        adjacent[u * MAX_N + v] = True
        adjacent[v * MAX_N + u] = True
        neighbors[u * MAX_N + degree[u]] = v
        degree[u] += 1
        neighbors[v * MAX_N + degree[v]] = u
        degree[v] += 1
        edge_u[e] = u
        edge_v[e] = v

    var reached = InlineArray[Bool, MAX_N]()
    var queue = InlineArray[Int, MAX_N]()
    var head = 0
    var tail = 1
    reached[0] = True
    queue[0] = 0
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacent[u * MAX_N + v] and not reached[v]:
                reached[v] = True
                queue[tail] = v
                tail += 1
    for v in range(n):
        if not reached[v]:
            return -1

    for i in range(m):
        for j in range(i + 1, m):
            let u = edge_u[i]
            let v = edge_v[i]
            let a = edge_u[j]
            let b = edge_v[j]
            var common = -1
            if u == a or u == b:
                common = u
            if v == a or v == b:
                if common < 0:
                    common = v
            if common >= 0:
                let p = if u == common: v else: u
                let q = if a == common: b else: a
                let ax = points[2 * p] - points[2 * common]
                let ay = points[2 * p + 1] - points[2 * common + 1]
                let bx = points[2 * q] - points[2 * common]
                let by = points[2 * q + 1] - points[2 * common + 1]
                if ax * by == ay * bx and ax * bx + ay * by > 0:
                    return -1
            elif pfc_intersects(points, u, v, a, b):
                return -1
    if n == 1:
        return 1

    for u in range(n):
        for i in range(1, degree[u]):
            let key = neighbors[u * MAX_N + i]
            var j = i
            while j > 0 and pfc_angle_less(key, neighbors[u * MAX_N + j - 1], u, points):
                neighbors[u * MAX_N + j] = neighbors[u * MAX_N + j - 1]
                j -= 1
            neighbors[u * MAX_N + j] = key

    var used = InlineArray[Bool, MAX_N * MAX_N]()
    var faces = 0
    for e in range(m):
        for direction in range(2):
            var u = edge_u[e] if direction == 0 else edge_v[e]
            var v = edge_v[e] if direction == 0 else edge_u[e]
            if used[u * MAX_N + v]:
                continue
            faces += 1
            var steps = 0
            while not used[u * MAX_N + v]:
                used[u * MAX_N + v] = True
                var reverse = -1
                for i in range(degree[v]):
                    if neighbors[v * MAX_N + i] == u:
                        reverse = i
                if reverse < 0 or degree[v] == 0:
                    return -1
                let next = neighbors[v * MAX_N + (reverse + 1) % degree[v]]
                u = v
                v = next
                steps += 1
                if steps > 2 * m:
                    return -1
    return Int64(faces)
