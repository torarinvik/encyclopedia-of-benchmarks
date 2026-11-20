use std::slice;

const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const INPUT_MAX: usize = 55;

struct Graph {
    n: usize, c: usize, m: usize, f: usize,
    outer_u: usize, outer_v: usize, outer_face: usize,
    degree: [usize; N], rotation: [[usize; N]; N],
    adjacent: [[bool; N]; N], edge_u: [usize; M], edge_v: [usize; M],
    mask: [usize; N], face_of: [[i32; N]; N],
}

impl Graph {
    fn connected(&self, mask: usize) -> bool {
        let start = (0..self.n).find(|&v| (mask >> v) & 1 != 0);
        let Some(start) = start else { return true; };
        let expected = (0..self.n).filter(|&v| (mask >> v) & 1 != 0).count();
        let mut seen = [false; N];
        let mut queue = [0usize; N];
        seen[start] = true; queue[0] = start;
        let mut head = 0; let mut tail = 1;
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..self.n {
                if (mask >> v) & 1 != 0 && self.adjacent[u][v] && !seen[v] {
                    seen[v] = true; queue[tail] = v; tail += 1;
                }
            }
        }
        tail == expected
    }
}

fn root(parent: &mut [usize; F], mut x: usize) -> usize {
    while parent[x] != x {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    x
}

fn parse(values: &[i64]) -> Option<Graph> {
    if !(4..=INPUT_MAX).contains(&values.len()) { return None; }
    let n = usize::try_from(values[0]).ok()?;
    let c = usize::try_from(values[1]).ok()?;
    if !(3..=N).contains(&n) || c > n - 2 { return None; }
    let outer_u = usize::try_from(values[2]).ok()?;
    let outer_v = usize::try_from(values[3]).ok()?;
    if outer_u >= n || outer_v >= n || outer_u == outer_v { return None; }
    let mut g = Graph {
        n, c, m: 0, f: 0, outer_u, outer_v, outer_face: 0,
        degree: [0; N], rotation: [[0; N]; N], adjacent: [[false; N]; N],
        edge_u: [0; M], edge_v: [0; M], mask: [0; N], face_of: [[-1; N]; N],
    };
    let mut offset = 4usize;
    let mut degree_sum = 0usize;
    for u in 0..n {
        let d = usize::try_from(*values.get(offset)?).ok()?; offset += 1;
        if d == 0 || d >= n || offset + d > values.len() { return None; }
        g.degree[u] = d; degree_sum += d;
        let mut row_seen = [false; N];
        for i in 0..d {
            let v = usize::try_from(values[offset + i]).ok()?;
            if v >= n || v == u || row_seen[v] { return None; }
            row_seen[v] = true; g.rotation[u][i] = v; g.adjacent[u][v] = true;
        }
        offset += d;
    }
    if degree_sum % 2 != 0 || offset + c != values.len() { return None; }
    g.m = degree_sum / 2;
    if g.m < n - 1 || g.m > M || !g.adjacent[outer_u][outer_v] { return None; }
    let mut edge_count = 0;
    for u in 0..n {
        for v in 0..n {
            if g.adjacent[u][v] != g.adjacent[v][u] { return None; }
            if u < v && g.adjacent[u][v] {
                g.edge_u[edge_count] = u; g.edge_v[edge_count] = v; edge_count += 1;
            }
        }
    }
    if edge_count != g.m { return None; }
    let full = (1usize << n) - 1;
    for i in 0..c {
        let raw = *values.get(offset + i)?;
        let mask = usize::try_from(raw).ok()?;
        if mask == 0 || mask >= full || mask.count_ones() < 2 { return None; }
        for j in 0..i {
            if g.mask[j] == mask { return None; }
            let common = g.mask[j] & mask;
            if common != 0 && common != g.mask[j] && common != mask { return None; }
        }
        g.mask[i] = mask;
        if !g.connected(mask) { return None; }
    }
    if !g.connected(full) { return None; }

    for e in 0..g.m {
        for side in 0..2 {
            let (su, sv) = if side == 0 { (g.edge_u[e], g.edge_v[e]) } else { (g.edge_v[e], g.edge_u[e]) };
            if g.face_of[su][sv] >= 0 { continue; }
            if g.f >= F { return None; }
            let mut local = [[false; N]; N];
            let (mut u, mut v) = (su, sv);
            let mut steps = 0;
            loop {
                if local[u][v] || g.face_of[u][v] >= 0 { return None; }
                local[u][v] = true; g.face_of[u][v] = g.f as i32;
                let at = g.rotation[v][..g.degree[v]].iter().position(|&x| x == u)?;
                let next = g.rotation[v][(at + 1) % g.degree[v]];
                (u, v) = (v, next);
                if (u, v) == (su, sv) { break; }
                steps += 1;
                if steps > 2 * g.m { return None; }
            }
            g.f += 1;
        }
    }
    if g.f != g.m - g.n + 2 { return None; }
    for u in 0..n { for v in 0..n {
        if g.adjacent[u][v] && g.face_of[u][v] < 0 { return None; }
    }}
    g.outer_face = g.face_of[outer_u][outer_v] as usize;
    Some(g)
}

fn solve(g: &Graph) -> i64 {
    for ci in 0..g.c {
        let mask = g.mask[ci];
        let mut parent = [0usize; F];
        for f in 0..g.f { parent[f] = f; }
        for e in 0..g.m {
            let (u, v) = (g.edge_u[e], g.edge_v[e]);
            if (mask >> u) & 1 != 0 && (mask >> v) & 1 != 0 { continue; }
            let a = root(&mut parent, g.face_of[u][v] as usize);
            let b = root(&mut parent, g.face_of[v][u] as usize);
            parent[a] = b;
        }
        let outside = root(&mut parent, g.outer_face);
        for v in 0..g.n {
            if (mask >> v) & 1 != 0 { continue; }
            let mut incident = false;
            for u in 0..g.n {
                if g.adjacent[v][u] {
                    incident = true;
                    if root(&mut parent, g.face_of[v][u] as usize) != outside { return 0; }
                }
            }
            if !incident { return -1; }
        }
        for e in 0..g.m {
            let (u, v) = (g.edge_u[e], g.edge_v[e]);
            if (mask >> u) & 1 != 0 && (mask >> v) & 1 != 0 { continue; }
            if root(&mut parent, g.face_of[u][v] as usize) != outside { return 0; }
        }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn c_connected_clustered_embedding_condition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > INPUT_MAX { return -1; }
    let values = slice::from_raw_parts(input, length);
    match parse(values) { Some(g) => solve(&g), None => -1 }
}
