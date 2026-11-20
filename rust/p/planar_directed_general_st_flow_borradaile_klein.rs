const N: usize = 6;
const M: usize = 10;
const DARTS: usize = 20;
const FACES: usize = 10;
const MAX_INPUT: usize = 61;
const MAX_AUGMENTATIONS: usize = 25;
const INF: i64 = i64::MAX / 4;

struct Graph {
    n: usize,
    m: usize,
    source: usize,
    sink: usize,
    tail: [usize; M],
    head: [usize; M],
    capacity: [i32; M],
    degree: [usize; N],
    rotation: [[usize; N]; N],
    local_position: [[i32; M]; N],
    left_face: [usize; DARTS],
    right_face: [usize; DARTS],
    face_count: usize,
    infinity_face: usize,
    root_anchor: usize,
}

fn dart_head(g: &Graph, dart: usize) -> usize {
    let e = dart / 2;
    if dart & 1 == 0 { g.head[e] } else { g.tail[e] }
}

fn left_successor(g: &Graph, dart: usize) -> Option<usize> {
    let vertex = dart_head(g, dart);
    let edge = dart / 2;
    let degree = g.degree[vertex];
    let position = g.local_position[vertex][edge];
    if degree == 0 || position < 0 { return None; }
    let prior = g.rotation[vertex][(position as usize + degree - 1) % degree];
    Some(2 * prior + usize::from(g.head[prior] == vertex))
}

fn decode(a: &[i64]) -> Option<Graph> {
    if a.len() < 4 || a.len() > MAX_INPUT { return None; }
    let (n0, m0, s0, t0) = (a[0], a[1], a[2], a[3]);
    if !(2..=N as i64).contains(&n0) || !(1..=M as i64).contains(&m0) ||
        s0 < 0 || s0 >= n0 || t0 < 0 || t0 >= n0 || s0 == t0 { return None; }
    let (n, m) = (n0 as usize, m0 as usize);
    if a.len() < 4 + 3 * m { return None; }
    let mut g = Graph {
        n, m, source: s0 as usize, sink: t0 as usize,
        tail: [0; M], head: [0; M], capacity: [0; M], degree: [0; N],
        rotation: [[0; N]; N], local_position: [[-1; M]; N],
        left_face: [0; DARTS], right_face: [0; DARTS], face_count: 0,
        infinity_face: 0, root_anchor: 0,
    };
    let mut pairs = [[false; N]; N];
    let mut at = 4;
    for e in 0..m {
        let (u, v, c) = (a[at], a[at + 1], a[at + 2]); at += 3;
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v || !(1..=5).contains(&c) { return None; }
        let (u, v) = (u as usize, v as usize);
        if pairs[u][v] || pairs[v][u] { return None; }
        pairs[u][v] = true; pairs[v][u] = true;
        g.tail[e] = u; g.head[e] = v; g.capacity[e] = c as i32;
    }
    let mut occurrence = [[0usize; 2]; M];
    let mut used = [[false; M]; N];
    for x in 0..n {
        if at >= a.len() { return None; }
        let d = a[at]; at += 1;
        if d < 1 || d >= n as i64 || at + d as usize > a.len() { return None; }
        g.degree[x] = d as usize;
        for j in 0..g.degree[x] {
            let raw = a[at]; at += 1;
            if raw < 0 || raw >= m as i64 { return None; }
            let e = raw as usize;
            if used[x][e] { return None; }
            used[x][e] = true; g.rotation[x][j] = e; g.local_position[x][e] = j as i32;
            if g.tail[e] == x { occurrence[e][0] += 1; }
            else if g.head[e] == x { occurrence[e][1] += 1; }
            else { return None; }
        }
    }
    if at != a.len() || (0..m).any(|e| occurrence[e] != [1, 1]) { return None; }

    let mut adjacent = [[false; N]; N];
    for e in 0..m { adjacent[g.tail[e]][g.head[e]] = true; adjacent[g.head[e]][g.tail[e]] = true; }
    let mut seen = [false; N]; let mut queue = [0usize; N];
    let (mut qh, mut qt) = (0usize, 1usize); seen[g.source] = true; queue[0] = g.source;
    while qh < qt {
        let x = queue[qh]; qh += 1;
        for y in 0..n { if adjacent[x][y] && !seen[y] { seen[y] = true; queue[qt] = y; qt += 1; } }
    }
    if seen[..n].iter().any(|&x| !x) { return None; }

    let mut face_of = [-1i32; DARTS];
    for start in 0..2 * m {
        if face_of[start] >= 0 { continue; }
        let mut dart = start;
        while face_of[dart] < 0 {
            face_of[dart] = g.face_count as i32;
            dart = left_successor(&g, dart)?;
        }
        if dart != start { return None; }
        g.face_count += 1;
    }
    if g.face_count != m - n + 2 { return None; }
    for dart in 0..2 * m {
        g.left_face[dart] = face_of[dart] as usize;
        g.right_face[dart] = face_of[dart ^ 1] as usize;
    }
    g.root_anchor = g.rotation[g.sink][0];
    let root_dart = 2 * g.root_anchor + usize::from(g.head[g.root_anchor] == g.sink);
    g.infinity_face = g.right_face[root_dart];
    Some(g)
}

fn visit(g: &Graph, vertex: usize, anchor: usize, root: bool,
         residual: &[[i32; N]; N], seen: &mut [bool; N], parent: &mut [i32; N]) {
    let degree = g.degree[vertex];
    let position = g.local_position[vertex][anchor] as usize;
    let first = if root { 0 } else { 1 };
    for step in first..first + degree {
        let edge = g.rotation[vertex][(position + step) % degree];
        let neighbor = if g.tail[edge] == vertex { g.head[edge] } else { g.tail[edge] };
        if !seen[neighbor] && residual[neighbor][vertex] > 0 {
            seen[neighbor] = true; parent[neighbor] = vertex as i32;
            visit(g, neighbor, edge, false, residual, seen, parent);
        }
    }
}

fn solve(g: &Graph) -> Option<i64> {
    let mut dual = [[INF; FACES]; FACES];
    for dart in 0..2 * g.m {
        let from = g.right_face[dart]; let to = g.left_face[dart];
        let weight = if dart & 1 == 0 { g.capacity[dart / 2] as i64 } else { 0 };
        dual[from][to] = dual[from][to].min(weight);
    }
    let mut dist = [INF; FACES]; let mut settled = [false; FACES]; dist[g.infinity_face] = 0;
    for _ in 0..g.face_count {
        let mut current = None;
        for f in 0..g.face_count { if !settled[f] && current.map_or(true, |c| dist[f] < dist[c]) { current = Some(f); } }
        let Some(c) = current else { break; };
        if dist[c] == INF { break; }
        settled[c] = true;
        for next in 0..g.face_count {
            if dual[c][next] != INF { dist[next] = dist[next].min(dist[c] + dual[c][next]); }
        }
    }
    let mut residual = [[0i32; N]; N];
    for e in 0..g.m {
        let eta = dist[g.left_face[2 * e]] - dist[g.right_face[2 * e]];
        if eta < 0 || eta > g.capacity[e] as i64 { return None; }
        residual[g.tail[e]][g.head[e]] += g.capacity[e] - eta as i32;
        residual[g.head[e]][g.tail[e]] += eta as i32;
    }
    let mut value = 0i64;
    for augmentation in 0..=MAX_AUGMENTATIONS {
        let mut seen = [false; N]; let mut parent = [-1i32; N]; seen[g.sink] = true;
        visit(g, g.sink, g.root_anchor, true, &residual, &mut seen, &mut parent);
        if !seen[g.source] { return Some(value); }
        if augmentation == MAX_AUGMENTATIONS { return None; }
        let mut delta = i32::MAX; let mut x = g.source;
        while x != g.sink { let y = parent[x] as usize; delta = delta.min(residual[x][y]); x = y; }
        x = g.source;
        while x != g.sink { let y = parent[x] as usize; residual[x][y] -= delta; residual[y][x] += delta; x = y; }
        value += delta as i64;
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn planar_directed_general_st_flow_borradaile_klein(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length > MAX_INPUT { return -1; }
    let Some(g) = decode(std::slice::from_raw_parts(input, length)) else { return -1; };
    let Some(value) = solve(&g) else { return -1; };
    if output.is_null() || capacity < 8 { return -2; }
    let bytes = (value as u64).to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, 8);
    8
}
