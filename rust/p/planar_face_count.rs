const MAX_N: usize = 16;
const MAX_M: usize = 42;
const MAX_INPUT: usize = 118;
const MAX_COORD: i64 = 100;

fn orient(a: (i64, i64), b: (i64, i64), c: (i64, i64)) -> i64 {
    (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0)
}
fn between(a: i64, b: i64, p: i64) -> bool { (a <= p && p <= b) || (b <= p && p <= a) }
fn on_segment(a: (i64, i64), b: (i64, i64), p: (i64, i64)) -> bool {
    between(a.0, b.0, p.0) && between(a.1, b.1, p.1)
}
fn intersects(a: (i64, i64), b: (i64, i64), c: (i64, i64), d: (i64, i64)) -> bool {
    let (ab_c, ab_d, cd_a, cd_b) = (orient(a,b,c), orient(a,b,d), orient(c,d,a), orient(c,d,b));
    (((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
     ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))) ||
    (ab_c == 0 && on_segment(a,b,c)) || (ab_d == 0 && on_segment(a,b,d)) ||
    (cd_a == 0 && on_segment(c,d,a)) || (cd_b == 0 && on_segment(c,d,b))
}
fn angle_half(dx: i64, dy: i64) -> i32 { if dy > 0 || (dy == 0 && dx >= 0) { 0 } else { 1 } }
fn angle_less(a: usize, b: usize, origin: usize, points: &[(i64, i64); MAX_N]) -> bool {
    let ax = points[a].0 - points[origin].0; let ay = points[a].1 - points[origin].1;
    let bx = points[b].0 - points[origin].0; let by = points[b].1 - points[origin].1;
    let ah = angle_half(ax, ay); let bh = angle_half(bx, by);
    ah < bh || (ah == bh && ax * by - ay * bx > 0)
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT { return -1; }
    if !(1..=MAX_N as i64).contains(&input[0]) || !(0..=MAX_M as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize; let m = input[1] as usize;
    let edge_cap = if n == 1 { 0 } else if n == 2 { 1 } else { 3 * n - 6 };
    if m > edge_cap || input.len() != 2 + 2 * n + 2 * m { return -1; }
    let mut points = [(0i64, 0i64); MAX_N];
    for v in 0..n {
        points[v] = (input[2 + 2 * v], input[3 + 2 * v]);
        if points[v].0 < -MAX_COORD || points[v].0 > MAX_COORD ||
            points[v].1 < -MAX_COORD || points[v].1 > MAX_COORD { return -1; }
        if points[..v].contains(&points[v]) { return -1; }
    }
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut edges = [(0usize, 0usize); MAX_M];
    let offset = 2 + 2 * n;
    for e in 0..m {
        let (u0, v0) = (input[offset + 2 * e], input[offset + 2 * e + 1]);
        if u0 < 0 || u0 >= n as i64 || v0 < 0 || v0 >= n as i64 || u0 == v0 { return -1; }
        let (u, v) = (u0 as usize, v0 as usize);
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true; adjacent[v][u] = true;
        neighbors[u][degree[u]] = v; degree[u] += 1;
        neighbors[v][degree[v]] = u; degree[v] += 1;
        edges[e] = (u, v);
    }
    let mut seen = [false; MAX_N]; let mut queue = [0usize; MAX_N];
    let (mut head, mut tail) = (0usize, 1usize); seen[0] = true; queue[0] = 0;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n { if adjacent[u][v] && !seen[v] { seen[v] = true; queue[tail] = v; tail += 1; } }
    }
    if seen[..n].iter().any(|&x| !x) { return -1; }
    for i in 0..m { for j in i + 1..m {
        let (u,v) = edges[i]; let (a,b) = edges[j];
        let common = if u == a || u == b { Some(u) } else if v == a || v == b { Some(v) } else { None };
        if let Some(c) = common {
            let p = if u == c { v } else { u }; let q = if a == c { b } else { a };
            let ax = points[p].0 - points[c].0; let ay = points[p].1 - points[c].1;
            let bx = points[q].0 - points[c].0; let by = points[q].1 - points[c].1;
            if ax * by == ay * bx && ax * bx + ay * by > 0 { return -1; }
        } else if intersects(points[u], points[v], points[a], points[b]) { return -1; }
    }}
    if n == 1 { return 1; }
    for u in 0..n { for i in 1..degree[u] {
        let key = neighbors[u][i]; let mut j = i;
        while j > 0 && angle_less(key, neighbors[u][j - 1], u, &points) {
            neighbors[u][j] = neighbors[u][j - 1]; j -= 1;
        }
        neighbors[u][j] = key;
    }}
    let mut used = [[false; MAX_N]; MAX_N]; let mut faces = 0i64;
    for &(a,b) in &edges[..m] { for (start_u,start_v) in [(a,b),(b,a)] {
        if used[start_u][start_v] { continue; }
        faces += 1; let (mut u,mut v) = (start_u,start_v); let mut steps = 0;
        while !used[u][v] {
            used[u][v] = true;
            let reverse = neighbors[v][..degree[v]].iter().position(|&x| x == u);
            if reverse.is_none() || degree[v] == 0 { return -1; }
            let next = neighbors[v][(reverse.unwrap() + 1) % degree[v]];
            (u,v) = (v,next); steps += 1;
            if steps > 2 * m { return -1; }
        }
    }}
    faces
}

#[no_mangle]
pub unsafe extern "C" fn planar_face_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
