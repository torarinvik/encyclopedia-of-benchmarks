package minimal_dominating_sets_permutation_graphs

import "core:c"

MAX_N :: 8
MAX_PARSEABLE_LENGTH :: 10
MAX_STATES :: 59049

Context :: struct {
    n: int,
    top: [MAX_N]int,
    top_vertex: [MAX_N]int,
    adj: [MAX_N][MAX_N]bool,
    ways: [MAX_STATES]i64,
}

graph_case :: proc(c: ^Context, i, j, k: int) -> int {
    a, b, d := c.top[i], c.top[j], c.top[k]
    if a < b && b < d do return 1
    if a < d && d < b do return 2
    if b < a && a < d do return 3
    if b < d && d < a do return 4
    if d < a && a < b do return 5
    return 0
}

covered :: proc(c: ^Context, y: int, selected: [5]int, count: int) -> bool {
    for z in 0..<count do if c.adj[selected[z]][y] do return true
    return false
}

irredundant :: proc(c: ^Context, selected: [5]int, count: int) -> bool {
    for x in 0..<count {
        found := false
        for y in 0..<c.n {
            if !c.adj[selected[x]][y] do continue
            shared := false
            for z in 0..<count do if z != x && c.adj[selected[z]][y] { shared = true; break }
            if !shared { found = true; break }
        }
        if !found do return false
    }
    return true
}

private_min_rank :: proc(c: ^Context, x: int, selected: [5]int, count: int) -> int {
    best := -1
    for y in 0..<c.n {
        if !c.adj[x][y] do continue
        shared := false
        for z in 0..<count do if selected[z] != x && c.adj[selected[z]][y] { shared = true; break }
        if !shared && (best < 0 || c.top[y] < c.top[best]) do best = y
    }
    return best
}

is_initial :: proc(c: ^Context, i, j, k, r, s: int) -> bool {
    tri := [5]int{i, j, k, 0, 0}
    if r != c.n || !irredundant(c, tri, 3) do return false
    kind := graph_case(c, i, j, k)
    if kind == 1 {
        for y in 0..<c.n do if y < i && c.top[y] < c.top[i] do return false
        return s == private_min_rank(c, i, tri, 3)
    }
    if kind == 2 {
        if s != c.n do return false
        for y in 0..<c.n do if c.top[y] < c.top[k] && y < j && !covered(c, y, tri, 3) do return false
        return true
    }
    if kind == 3 {
        for y in 0..<c.n do if c.top[y] < c.top[j] && y < i do return false
        return s == private_min_rank(c, j, tri, 3)
    }
    if kind == 4 {
        if s != c.n do return false
        for y in 0..<c.n do if c.top[y] < c.top[j] && y < i && !covered(c, y, tri, 3) do return false
        return true
    }
    if kind == 5 {
        for y in 0..<c.n do if c.top[y] < c.top[k] && y < i do return false
        return s == private_min_rank(c, k, tri, 3)
    }
    return false
}

is_regular :: proc(c: ^Context, i, j, k, r, s: int) -> bool {
    tri := [5]int{i, j, k, 0, 0}
    if !irredundant(c, tri, 3) do return false
    kind := graph_case(c, i, j, k)
    if kind >= 1 && kind <= 4 { if r < 0 || r >= i do return false }
    else if kind == 5 { if r != c.n do return false }
    else return false
    if kind == 2 || kind == 4 do return s == c.n
    if s < 0 || s >= c.n do return false
    if kind == 1 do return c.adj[i][s] && !c.adj[r][s] && !c.adj[j][s] && !c.adj[k][s]
    if kind == 3 do return c.adj[j][s] && !c.adj[r][s] && !c.adj[i][s] && !c.adj[k][s]
    return c.adj[k][s] && !c.adj[i][s] && !c.adj[j][s]
}

is_final :: proc(c: ^Context, i, j, k, r: int) -> bool {
    selected := [5]int{i, j, k, 0, 0}
    count := 3
    if r != c.n { selected = [5]int{r, i, j, k, 0}; count = 4 }
    for y in 0..<c.n do if i < y && c.top[i] < c.top[y] && !covered(c, y, selected, count) do return false
    return true
}

state_index :: proc(i, j, k, r, s, base: int) -> int {
    return ((((i*base+j)*base+k)*base+r)*base+s)
}

successor :: proc(c: ^Context, i, j, k, r, s, ell: int, out_r, out_s: ^int) -> bool {
    kind := graph_case(c, j, k, ell)
    if kind == 0 do return false
    selected := [5]int{i, j, k, ell, 0}
    count := 4
    if r != c.n { selected = [5]int{r, i, j, k, ell}; count = 5 }
    if !irredundant(c, selected, count) || (s != c.n && c.top[ell] <= c.top[s]) do return false
    if !c.adj[j][k] {
        for y in 0..<c.n do if i < y && y < j && c.top[i] < c.top[y] && c.top[y] < c.top[j] && !covered(c, y, selected, count) do return false
    }
    if c.adj[i][k] {
        for y in 0..<c.n do if j < y && y < k && c.top[j] < c.top[y] && c.top[y] < c.top[ell] && !covered(c, y, selected, count) do return false
    }
    if kind == 5 do out_r^ = c.n
    else {
        max_rank := c.top[i]
        if r != c.n && c.top[r] > max_rank do max_rank = c.top[r]
        out_r^ = c.top_vertex[max_rank]
    }
    if kind == 2 || kind == 4 do out_s^ = c.n
    else {
        old_min := c.top[i]
        if c.top[j] < old_min do old_min = c.top[j]
        if c.top[k] < old_min do old_min = c.top[k]
        new_min := c.top[j]
        if c.top[k] < new_min do new_min = c.top[k]
        if c.top[ell] < new_min do new_min = c.top[ell]
        if s != c.n && old_min == new_min do out_s^ = s
        else {
            y := j
            if c.top[k] < c.top[y] do y = k
            if c.top[ell] < c.top[y] do y = ell
            out_s^ = private_min_rank(c, y, selected, count)
            if out_s^ < 0 do return false
        }
    }
    return is_regular(c, j, k, ell, out_r^, out_s^)
}

dominates :: proc(mask: u32, hoods: [MAX_N]u32, n: int) -> bool {
    cover: u32 = 0
    for x in 0..<n do if mask & (1<<x) != 0 do cover |= hoods[x]
    return cover == (1<<n)-1
}

@(export)
minimal_dominating_sets_permutation_graphs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if input[0] < 1 || input[0] > MAX_N do return -1
    n := int(input[0])
    if length != c.size_t(n+1) do return -1
    ctx := new(Context)
    defer delete(ctx)
    ctx^ = Context{}
    ctx.n = n
    seen: [MAX_N]bool
    for x in 0..<n {
        rank := input[x+1]
        if rank < 0 || rank >= i64(n) do return -1
        ri := int(rank)
        if seen[ri] do return -1
        seen[ri] = true
        ctx.top[x] = ri
        ctx.top_vertex[ri] = x
        ctx.adj[x][x] = true
    }
    for x in 0..<n do for y in x+1..<n {
        ctx.adj[x][y] = ctx.top[x] > ctx.top[y]
        ctx.adj[y][x] = ctx.adj[x][y]
    }
    answer: i64 = 0
    if n >= 3 {
        for i := n-3; i >= 0; i -= 1 {
            for j in i+1..<n-1 do for k in j+1..<n {
                tri := [5]int{i,j,k,0,0}
                if graph_case(ctx,i,j,k)==0 || !irredundant(ctx,tri,3) do continue
                for ri in 0..=i {
                    r := ri
                    if ri == i do r=n
                    for s in 0..=n {
                        if !is_initial(ctx,i,j,k,r,s) && !is_regular(ctx,i,j,k,r,s) do continue
                        paths: i64 = 0
                        if is_final(ctx,i,j,k,r) do paths=1
                        for ell in k+1..<n {
                            nr,ns: int
                            if successor(ctx,i,j,k,r,s,ell,&nr,&ns) do paths+=ctx.ways[state_index(j,k,ell,nr,ns,n+1)]
                        }
                        ctx.ways[state_index(i,j,k,r,s,n+1)] = paths
                        if is_initial(ctx,i,j,k,r,s) do answer += paths
                    }
                }
            }
        }
    }
    hoods: [MAX_N]u32
    for x in 0..<n do for y in 0..<n do if ctx.adj[x][y] do hoods[x] |= 1<<y
    full: u32 = (1<<n)-1
    for mask: u32 = 1; mask <= full; mask += 1 {
        size := 0
        bits := mask
        for bits != 0 { size += int(bits&1); bits >>= 1 }
        if size > 2 || !dominates(mask,hoods,n) do continue
        minimal := true
        for x in 0..<n do if mask&(1<<x)!=0 && dominates(mask^(1<<x),hoods,n) do minimal=false
        if minimal do answer += 1
    }
    return answer
}
