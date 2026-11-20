package gpsr_perimeter_recovery_trace

import "core:c"

MAX_N :: 8
MAX_M :: 18
MAX_PATH :: 37
MAX_INPUT :: 57
MAX_OUTPUT :: 896
MAX_OUTPUT_WORDS :: 112

Point :: struct { x, y: i64 }
Edge :: struct { u, v: int }

cross :: proc(ax, ay, bx, by: i64) -> i64 { return ax*by - ay*bx }

orient :: proc(points: [MAX_N]Point, a, b, c: int) -> i64 {
    return cross(points[b].x-points[a].x, points[b].y-points[a].y,
                 points[c].x-points[a].x, points[c].y-points[a].y)
}

half_plane :: proc(x, y: i64) -> int {
    if y > 0 || (y == 0 && x >= 0) do return 0
    return 1
}

angle_less :: proc(ax, ay: i64, ai: int, bx, by: i64, bi: int) -> bool {
    ah, bh := half_plane(ax, ay), half_plane(bx, by)
    if ah != bh do return ah < bh
    turn := cross(ax, ay, bx, by)
    if turn != 0 do return turn > 0
    return ai < bi
}

segments_cross :: proc(points: [MAX_N]Point, a, b, c, d: int) -> bool {
    return orient(points, a, b, c)*orient(points, a, b, d) < 0 &&
           orient(points, c, d, a)*orient(points, c, d, b) < 0
}

gcd64 :: proc(a0, b0: i64) -> i64 {
    a, b := a0, b0
    for b != 0 {
        a, b = b, a % b
    }
    return a
}

proper_crossing :: proc(p, q, a, b: Point, numerator, denominator: ^i64) -> bool {
    rx, ry := q.x-p.x, q.y-p.y
    sx, sy := b.x-a.x, b.y-a.y
    den := cross(rx, ry, sx, sy)
    if den == 0 do return false
    ox, oy := a.x-p.x, a.y-p.y
    tn, un := cross(ox, oy, sx, sy), cross(ox, oy, rx, ry)
    if den < 0 { den, tn, un = -den, -tn, -un }
    if !(tn > 0 && tn < den && un > 0 && un < den) do return false
    divisor := gcd64(tn, den)
    numerator^ = tn/divisor
    denominator^ = den/divisor
    return true
}

edge_id :: proc(u0, v0, m: int, edges: [MAX_M]Edge) -> int {
    lo, hi := min(u0, v0), max(u0, v0)
    for i := 0; i < m; i += 1 {
        if edges[i].u == lo && edges[i].v == hi do return i
    }
    return -1
}

next_ccw :: proc(node, incoming: int, degree: [MAX_N]int,
                 rotation: [MAX_N][MAX_N]int) -> int {
    for i := 0; i < degree[node]; i += 1 {
        if rotation[node][i] == incoming do return rotation[node][(i+1)%degree[node]]
    }
    return -1
}

first_ccw :: proc(node, target: int, points: [MAX_N]Point,
                  degree: [MAX_N]int, adjacency: [MAX_N][MAX_N]int) -> int {
    rx, ry := points[target].x-points[node].x, points[target].y-points[node].y
    best := -1
    best_x, best_y: i64
    for i := 0; i < degree[node]; i += 1 {
        v := adjacency[node][i]
        dx, dy := points[v].x-points[node].x, points[v].y-points[node].y
        vx, vy := rx*dx+ry*dy, cross(rx, ry, dx, dy)
        if best < 0 || angle_less(vx, vy, v, best_x, best_y, best) {
            best, best_x, best_y = v, vx, vy
        }
    }
    return best
}

put64 :: proc(output: [^]u8, position: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[position+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gpsr_perimeter_recovery_trace :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT do return -1
    n64, m64, source64, target64 := input[0], input[1], input[2], input[3]
    if n64 < 3 || n64 > MAX_N do return -1
    max_edges := 3*n64 - 6
    if max_edges > MAX_M do max_edges = MAX_M
    if m64 < n64-1 || m64 > max_edges ||
       source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64 || source64 == target64 do return -1
    n, m, source, target := int(n64), int(m64), int(source64), int(target64)
    if length != c.size_t(4+2*n+2*m) do return -1

    points: [MAX_N]Point
    for i := 0; i < n; i += 1 {
        points[i] = Point{input[4+i], input[4+n+i]}
        if points[i].x < -16 || points[i].x > 16 || points[i].y < -16 || points[i].y > 16 do return -1
        for j := 0; j < i; j += 1 {
            if points[i].x == points[j].x && points[i].y == points[j].y do return -1
        }
    }
    for i := 0; i < n; i += 1 {
        for j := i+1; j < n; j += 1 {
            for k := j+1; k < n; k += 1 {
                if orient(points, i, j, k) == 0 do return -1
            }
        }
    }

    edges: [MAX_M]Edge
    adjacency: [MAX_N][MAX_N]int
    degree: [MAX_N]int
    edge_start := 4+2*n
    for i := 0; i < m; i += 1 {
        u64, v64 := input[edge_start+2*i], input[edge_start+2*i+1]
        if u64 < 0 || v64 >= n64 || u64 >= v64 do return -1
        u, v := int(u64), int(v64)
        if i > 0 && (edges[i-1].u > u || (edges[i-1].u == u && edges[i-1].v >= v)) do return -1
        edges[i] = Edge{u, v}
        adjacency[u][degree[u]], adjacency[v][degree[v]] = v, u
        degree[u] += 1
        degree[v] += 1
    }

    reached: [MAX_N]bool
    queue: [MAX_N]int
    head, tail := 0, 1
    reached[source] = true
    queue[0] = source
    for head < tail {
        u := queue[head]
        head += 1
        for i := 0; i < degree[u]; i += 1 {
            v := adjacency[u][i]
            if !reached[v] {
                reached[v] = true
                queue[tail] = v
                tail += 1
            }
        }
    }
    for i := 0; i < n; i += 1 { if !reached[i] do return -1 }

    for i := 0; i < m; i += 1 {
        for j := i+1; j < m; j += 1 {
            a, b, c, d := edges[i].u, edges[i].v, edges[j].u, edges[j].v
            if a != c && a != d && b != c && b != d && segments_cross(points, a, b, c, d) do return -1
        }
    }

    sx, sy := points[source].x-points[target].x, points[source].y-points[target].y
    source_distance := sx*sx+sy*sy
    for i := 0; i < degree[source]; i += 1 {
        v := adjacency[source][i]
        dx, dy := points[v].x-points[target].x, points[v].y-points[target].y
        if dx*dx+dy*dy < source_distance do return -1
    }
    if output == nil || capacity < MAX_OUTPUT do return -2

    rotation: [MAX_N][MAX_N]int
    for u := 0; u < n; u += 1 {
        for i := 0; i < degree[u]; i += 1 { rotation[u][i] = adjacency[u][i] }
        for i := 1; i < degree[u]; i += 1 {
            v := rotation[u][i]
            dx, dy := points[v].x-points[u].x, points[v].y-points[u].y
            j := i
            for j > 0 {
                w := rotation[u][j-1]
                if !angle_less(dx, dy, v, points[w].x-points[u].x, points[w].y-points[u].y, w) do break
                rotation[u][j] = w
                j -= 1
            }
            rotation[u][j] = v
        }
    }

    path: [MAX_PATH]int
    events: [MAX_M][4]i64
    path_count, crossing_count := 1, 0
    current, previous := source, -1
    e0u, e0v := -1, -1
    lf_num, lf_den: i64 = 0, 1
    status: i64 = 0
    path[0] = source
    for {
        dx, dy := points[current].x-points[target].x, points[current].y-points[target].y
        if current == target { status = 2; break }
        if dx*dx+dy*dy < source_distance { status = 1; break }
        if path_count-1 >= 2*m { status = 0; break }
        candidate := -1
        if previous < 0 {
            candidate = first_ccw(current, target, points, degree, adjacency)
        } else {
            candidate = next_ccw(current, previous, degree, rotation)
        }
        if candidate < 0 { status = 0; break }
        changed_face, invalid_state := false, false
        for {
            t_num, t_den: i64 = 0, 1
            if !proper_crossing(points[source], points[target], points[current], points[candidate], &t_num, &t_den) ||
               t_num*lf_den <= lf_num*t_den { break }
            id := edge_id(current, candidate, m, edges)
            if id < 0 || crossing_count >= MAX_M { status = 0; invalid_state = true; break }
            events[crossing_count] = [4]i64{i64(path_count-1), i64(id), t_num, t_den}
            crossing_count += 1
            lf_num, lf_den = t_num, t_den
            changed_face = true
            candidate = next_ccw(current, candidate, degree, rotation)
            if candidate < 0 { status = 0; invalid_state = true; break }
        }
        if invalid_state do break
        if changed_face || e0u < 0 { e0u, e0v = current, candidate }
        else if e0u == current && e0v == candidate { status = 0; break }
        previous, current = current, candidate
        if path_count >= MAX_PATH { status = 0; break }
        path[path_count] = current
        path_count += 1
    }

    words: [MAX_OUTPUT_WORDS]i64
    word_count := 0
    words[word_count] = status; word_count += 1
    words[word_count] = i64(path_count-1); word_count += 1
    for i := 0; i < path_count; i += 1 { words[word_count] = i64(path[i]); word_count += 1 }
    words[word_count] = i64(crossing_count); word_count += 1
    for i := 0; i < crossing_count; i += 1 {
        for j := 0; j < 4; j += 1 { words[word_count] = events[i][j]; word_count += 1 }
    }
    for i := 0; i < word_count; i += 1 { put64(output, 8*i, words[i]) }
    return i64(8*word_count)
}
