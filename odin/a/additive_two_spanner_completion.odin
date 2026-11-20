package additive_two_spanner_completion
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 59
INF :: 9

put :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { out[at+byte] = u8(bits & 255); bits >>= 8 }
}

distances :: proc(n, m: int, u, v: [MAX_M]int, selected: [MAX_M]bool,
                  only_selected: bool) -> [MAX_N][MAX_N]int {
    d: [MAX_N][MAX_N]int
    for left := 0; left < n; left += 1 {
        for right := 0; right < n; right += 1 { d[left][right] = INF }
        d[left][left] = 0
    }
    for edge := 0; edge < m; edge += 1 {
        if only_selected && !selected[edge] do continue
        d[u[edge]][v[edge]] = 1
        d[v[edge]][u[edge]] = 1
    }
    for via := 0; via < n; via += 1 {
        for left := 0; left < n; left += 1 {
            for right := 0; right < n; right += 1 {
                candidate := d[left][via] + d[via][right]
                if candidate < d[left][right] { d[left][right] = candidate }
            }
        }
    }
    return d
}

@(export)
additive_two_spanner_completion :: proc "c"(
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 28 || length != c.size_t(2 + 2*m64) do return -1
    n, m := int(n64), int(m64)
    u: [MAX_M]int
    v: [MAX_M]int
    for edge := 0; edge < m; edge += 1 {
        a, b := input[2+2*edge], input[3+2*edge]
        if a < 0 || a >= b || b >= n64 do return -1
        u[edge], v[edge] = int(a), int(b)
        for prior := 0; prior < edge; prior += 1 {
            if u[prior] == u[edge] && v[prior] == v[edge] do return -1
        }
    }
    selected: [MAX_M]bool
    original := distances(n, m, u, v, selected, false)
    for round := 0; round <= m; round += 1 {
        current := distances(n, m, u, v, selected, true)
        source, target := n, n
        for a := 0; a < n; a += 1 {
            if source != n do break
            for b := a+1; b < n; b += 1 {
                if original[a][b] < INF && current[a][b] > original[a][b]+2 {
                    source, target = a, b
                    break
                }
            }
        }
        if source == n do break
        if round == m do return -1
        vertex := source
        for vertex != target {
            next := n
            for neighbor := 0; neighbor < n; neighbor += 1 {
                if neighbor == vertex || original[neighbor][target]+1 != original[vertex][target] do continue
                for edge := 0; edge < m; edge += 1 {
                    if (u[edge] == vertex && v[edge] == neighbor) || (v[edge] == vertex && u[edge] == neighbor) {
                        next = neighbor
                        selected[edge] = true
                        break
                    }
                }
                if next != n do break
            }
            if next == n do return -1
            vertex = next
        }
    }
    count := 0
    for edge := 0; edge < m; edge += 1 { if selected[edge] { count += 1 } }
    bytes := 8 * (1 + 2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put(output, 0, i64(count))
    slot := 0
    for edge := 0; edge < m; edge += 1 {
        if !selected[edge] do continue
        put(output, 8*(1+2*slot), i64(u[edge]))
        put(output, 8*(2+2*slot), i64(v[edge]))
        slot += 1
    }
    return i64(bytes)
}
