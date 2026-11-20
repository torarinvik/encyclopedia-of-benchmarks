module elkin_peleg_sparse_spanner

const max_n = 20
const max_m = 190
const max_input = 383
const inf = 1000

struct Cluster {
mut:
    center int
    radius int
    members []bool
    tree []bool
}

struct Context {
mut:
    n int
    m int
    adjacent [][]bool
    edge_index [][]int
    distance [][]int
}

fn (c &Context) edge_id(a int, b int) int {
    return if a < b { c.edge_index[a][b] } else { c.edge_index[b][a] }
}

fn (c &Context) bfs(source int, allowed []bool) ([]int, []int) {
    mut parent := []int{len: c.n, init: -1}
    mut distance := []int{len: c.n, init: inf}
    mut queue := []int{len: c.n}
    mut head := 0
    mut tail := 0
    distance[source] = 0
    queue[tail] = source
    tail++
    for head < tail {
        u := queue[head]
        head++
        for v in 0 .. c.n {
            if c.adjacent[u][v] && (allowed.len == 0 || allowed[v]) && distance[v] == inf {
                distance[v] = distance[u] + 1
                parent[v] = u
                queue[tail] = v
                tail++
            }
        }
    }
    return parent, distance
}

fn (c &Context) add_tree(allowed []bool, root int, chosen []bool) int {
    parent, distance := c.bfs(root, allowed)
    mut radius := 0
    for v in 0 .. c.n {
        if allowed[v] {
            if distance[v] > radius { radius = distance[v] }
            if v != root {
                e := c.edge_id(v, parent[v])
                if e >= 0 { chosen[e] = true }
            }
        }
    }
    return radius
}

fn (c &Context) set_distance(left []bool, right []bool) int {
    mut best := inf
    for u in 0 .. c.n {
        if left[u] {
            for v in 0 .. c.n {
                if right[v] && c.distance[u][v] < best { best = c.distance[u][v] }
            }
        }
    }
    return best
}

fn cluster_before(a Cluster, b Cluster, n int) bool {
    if a.center != b.center { return a.center < b.center }
    for v in 0 .. n {
        if a.members[v] != b.members[v] { return a.members[v] }
    }
    return false
}

fn (c &Context) add_connector(left []bool, right []bool, chosen []bool) {
    mut best_distance := inf
    mut best_path := []int{}
    for source in 0 .. c.n {
        if !left[source] { continue }
        parent, distance := c.bfs(source, []bool{})
        for target in 0 .. c.n {
            if !right[target] || distance[target] == inf || distance[target] > best_distance { continue }
            mut reversed := []int{}
            mut vertex := target
            for vertex >= 0 && reversed.len < max_n {
                reversed << vertex
                if vertex == source { break }
                vertex = parent[vertex]
            }
            if reversed.len == 0 || reversed[reversed.len - 1] != source { continue }
            mut earlier := best_path.len == 0 || distance[target] < best_distance
            if !earlier && distance[target] == best_distance {
                for i in 0 .. reversed.len {
                    candidate := reversed[reversed.len - 1 - i]
                    if candidate != best_path[i] {
                        earlier = candidate < best_path[i]
                        break
                    }
                }
            }
            if earlier {
                best_distance = distance[target]
                best_path.clear()
                for i in 0 .. reversed.len { best_path << reversed[reversed.len - 1 - i] }
            }
        }
    }
    for i in 1 .. best_path.len {
        e := c.edge_id(best_path[i - 1], best_path[i])
        if e >= 0 { chosen[e] = true }
    }
}

fn sigma(n int) int {
    mut value := 1
    for value * value * value * value < n { value++ }
    return value
}

fn (c &Context) supercluster(input []Cluster, threshold int, delta int, chosen []bool) []Cluster {
    mut active := []bool{len: input.len, init: true}
    mut output := []Cluster{}
    for {
        mut best := -1
        mut neighborhoods := [][]bool{len: input.len}
        for i in 0 .. input.len { neighborhoods[i] = []bool{len: input.len, init: false} }
        for i in 0 .. input.len {
            if !active[i] { continue }
            mut count := 0
            for j in 0 .. input.len {
                if active[j] && c.set_distance(input[i].members, input[j].members) <= delta {
                    neighborhoods[i][j] = true
                    count++
                }
            }
            if count >= threshold && (best < 0 || cluster_before(input[i], input[best], c.n)) { best = i }
        }
        if best < 0 { break }
        mut members := []bool{len: c.n, init: false}
        mut tree := []bool{len: c.m, init: false}
        for j in 0 .. input.len {
            if !neighborhoods[best][j] { continue }
            active[j] = false
            for v in 0 .. c.n { members[v] = members[v] || input[j].members[v] }
            for e in 0 .. c.m { tree[e] = tree[e] || input[j].tree[e]; chosen[e] = chosen[e] || input[j].tree[e] }
            if j != best { c.add_connector(input[best].members, input[j].members, chosen) }
        }
        output << Cluster{center: input[best].center, radius: 0, members: members, tree: tree}
    }
    mut remaining := []int{}
    for i in 0 .. input.len { if active[i] { remaining << i } }
    for i in 1 .. remaining.len {
        key := remaining[i]
        mut j := i
        for j > 0 && cluster_before(input[key], input[remaining[j - 1]], c.n) {
            remaining[j] = remaining[j - 1]
            j--
        }
        remaining[j] = key
    }
    for i in 0 .. remaining.len {
        for j in i + 1 .. remaining.len {
            a := input[remaining[i]]
            b := input[remaining[j]]
            if c.set_distance(a.members, b.members) <= delta { c.add_connector(a.members, b.members, chosen) }
        }
    }
    return output
}

fn (mut c Context) construct() []bool {
    for source in 0 .. c.n {
        _, distance := c.bfs(source, []bool{})
        for v in 0 .. c.n { c.distance[source][v] = distance[v] }
    }
    mut chosen := []bool{len: c.m, init: false}
    mut uncovered := []bool{len: c.n, init: true}
    mut ground := []Cluster{}
    for {
        mut root := -1
        for v in 0 .. c.n { if uncovered[v] { root = v; break } }
        if root < 0 { break }
        mut members := []bool{len: c.n, init: false}
        members[root] = true
        mut size := 1
        for {
            mut shell := members.clone()
            for v in 0 .. c.n {
                if !shell[v] && uncovered[v] {
                    for u in 0 .. c.n { if members[u] && c.adjacent[u][v] { shell[v] = true; break } }
                }
            }
            mut shell_size := 0
            for has in shell { if has { shell_size++ } }
            if shell_size == size || shell_size * shell_size * shell_size * shell_size < c.n * size * size * size * size { break }
            for v in 0 .. c.n { if shell[v] && !members[v] { members[v] = true; size++ } }
        }
        mut shell := members.clone()
        for v in 0 .. c.n {
            if !shell[v] && uncovered[v] {
                for u in 0 .. c.n { if members[u] && c.adjacent[u][v] { shell[v] = true; break } }
            }
        }
        mut tree_flags := []bool{len: c.m, init: false}
        radius := c.add_tree(members, root, tree_flags)
        mut shell_flags := []bool{len: c.m, init: false}
        c.add_tree(shell, root, shell_flags)
        for e in 0 .. c.m { chosen[e] = chosen[e] || shell_flags[e] }
        ground << Cluster{center: root, radius: radius, members: members, tree: tree_flags}
        for v in 0 .. c.n { if members[v] { uncovered[v] = false } }
    }
    mut level := []Cluster{}
    for cluster in ground { if cluster.radius == 1 { level << cluster } }
    mut final_clusters := c.supercluster(level, sigma(c.n), 16, chosen)
    for cluster in ground { if cluster.radius == 2 || cluster.radius == 3 { final_clusters << cluster } }
    for i in 1 .. final_clusters.len {
        key := final_clusters[i]
        mut j := i
        for j > 0 && cluster_before(key, final_clusters[j - 1], c.n) {
            final_clusters[j] = final_clusters[j - 1]
            j--
        }
        final_clusters[j] = key
    }
    for i in 0 .. final_clusters.len {
        for j in i + 1 .. final_clusters.len {
            if c.set_distance(final_clusters[i].members, final_clusters[j].members) <= 128 {
                c.add_connector(final_clusters[i].members, final_clusters[j].members, chosen)
            }
        }
    }
    return chosen
}

@[export: 'elkin_peleg_sparse_spanner']
pub fn elkin_peleg_sparse_spanner(a &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { a == nil } || length < 2 || length > max_input { return -1 }
    n64 := unsafe { a[0] }
    m64 := unsafe { a[1] }
    if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return -1 }
    mut adjacent := [][]bool{len: int(n64)}
    mut edge_index := [][]int{len: int(n64)}
    mut distance := [][]int{len: int(n64)}
    for i in 0 .. int(n64) {
        adjacent[i] = []bool{len: int(n64), init: false}
        edge_index[i] = []int{len: int(n64), init: -1}
        distance[i] = []int{len: int(n64), init: inf}
    }
    mut c := Context{n: int(n64), m: int(m64), adjacent: adjacent, edge_index: edge_index, distance: distance}
    for e in 0 .. c.m {
        u64 := unsafe { a[2 + 2 * e] }
        v64 := unsafe { a[3 + 2 * e] }
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
        u := int(u64)
        v := int(v64)
        if c.edge_index[u][v] >= 0 { return -1 }
        c.edge_index[u][v] = e
        c.edge_index[v][u] = e
        c.adjacent[u][v] = true
        c.adjacent[v][u] = true
    }
    if unsafe { output == nil } || capacity < c.m { return -2 }
    chosen := c.construct()
    for e in 0 .. c.m { unsafe { output[e] = if chosen[e] { u8(1) } else { u8(0) } } }
    return i64(c.m)
}
