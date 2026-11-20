const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 67;
const MAX_PIECES: usize = 56;
const MAX_SPLITS: usize = 28;
const MODULUS: i64 = 998_244_353;
const KIND_S: i32 = 1;
const KIND_P: i32 = 2;
const KIND_R: i32 = 3;

#[derive(Clone, Copy)]
struct EdgeRef { u: usize, v: usize, pair_id: i32, real: bool }
impl Default for EdgeRef {
    fn default() -> Self { Self { u: 0, v: 0, pair_id: -1, real: true } }
}
#[derive(Clone, Copy)]
struct Piece { edge_count: usize, edges: [EdgeRef; MAX_M] }
impl Default for Piece {
    fn default() -> Self { Self { edge_count: 0, edges: [EdgeRef::default(); MAX_M] } }
}

fn connected_without(adjacency: &[[bool; MAX_N]; MAX_N], n: usize, removed: i32) -> bool {
    let mut start = 0usize;
    while start as i32 == removed { start += 1; }
    let mut seen = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    seen[start] = true; queue[0] = start;
    let (mut head, mut tail) = (0usize, 1usize);
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n {
            if v as i32 != removed && adjacency[u][v] && !seen[v] {
                seen[v] = true; queue[tail] = v; tail += 1;
            }
        }
    }
    let reached = (0..n).filter(|&v| v as i32 != removed && seen[v]).count();
    reached == n - (if removed >= 0 { 1 } else { 0 })
}

fn components_after_pair(piece: &Piece, n: usize, a: usize, b: usize) -> ([i32; MAX_N], usize) {
    let mut component = [-1i32; MAX_N];
    let mut count = 0usize;
    let mut queue = [0usize; MAX_N];
    for start in 0..n {
        if start == a || start == b || component[start] >= 0 { continue; }
        component[start] = count as i32; queue[0] = start;
        let (mut head, mut tail) = (0usize, 1usize);
        while head < tail {
            let u = queue[head]; head += 1;
            for edge in piece.edges.iter().take(piece.edge_count) {
                if edge.u == a || edge.u == b || edge.v == a || edge.v == b { continue; }
                let other = if edge.u == u { Some(edge.v) } else if edge.v == u { Some(edge.u) } else { None };
                if let Some(v) = other {
                    if component[v] < 0 { component[v] = count as i32; queue[tail] = v; tail += 1; }
                }
            }
        }
        count += 1;
    }
    (component, count)
}

fn find_split(piece: &Piece, n: usize) -> Option<(usize, usize, [bool; MAX_M])> {
    let ecount = piece.edge_count;
    for u in 0..n { for v in (u + 1)..n {
        let (component, component_count) = components_after_pair(piece, n, u, v);
        let mut edge_class = [0usize; MAX_M];
        let mut sizes = [0usize; MAX_M];
        let mut direct_count = 0usize;
        for e in 0..ecount {
            let edge = piece.edges[e];
            if (edge.u == u && edge.v == v) || (edge.u == v && edge.v == u) {
                edge_class[e] = component_count + direct_count; direct_count += 1;
            } else {
                let endpoint = if edge.u != u && edge.u != v { edge.u } else { edge.v };
                if component[endpoint] < 0 { return None; }
                edge_class[e] = component[endpoint] as usize;
            }
            if edge_class[e] >= MAX_M { return None; }
            sizes[edge_class[e]] += 1;
        }
        let class_count = component_count + direct_count;
        let selected = (0..class_count).find(|&c| sizes[c] >= 2 && sizes[c] <= ecount - 2);
        let use_first_two = selected.is_none() && class_count >= 4 && class_count == ecount
            && (0..class_count).all(|c| sizes[c] == 1);
        if selected.is_none() && !use_first_two { continue; }
        let mut left = [false; MAX_M];
        for e in 0..ecount { left[e] = if let Some(c) = selected { edge_class[e] == c } else { edge_class[e] < 2 }; }
        return Some((u, v, left));
    }}
    None
}

fn piece_kind(piece: &Piece) -> i32 {
    let mut present = [false; MAX_N];
    let mut vertex_count = 0usize;
    for edge in piece.edges.iter().take(piece.edge_count) {
        for endpoint in [edge.u, edge.v] {
            if !present[endpoint] { present[endpoint] = true; vertex_count += 1; }
        }
    }
    if vertex_count == 2 && piece.edge_count >= 3 { return KIND_P; }
    if vertex_count == 3 && piece.edge_count == 3 {
        let mut pair = [[false; MAX_N]; MAX_N];
        for edge in piece.edges.iter().take(3) { pair[edge.u][edge.v] = true; pair[edge.v][edge.u] = true; }
        let mut count = 0;
        for u in 0..MAX_N { for v in (u + 1)..MAX_N { if pair[u][v] { count += 1; } }}
        if count == 3 { return KIND_S; }
    }
    KIND_R
}

fn find_root(parent: &mut [usize; MAX_PIECES], mut item: usize) -> usize {
    while parent[item] != item { parent[item] = parent[parent[item]]; item = parent[item]; }
    item
}
fn unite(parent: &mut [usize; MAX_PIECES], left: usize, right: usize) {
    let a = find_root(parent, left); let b = find_root(parent, right);
    if a != b { parent[b] = a; }
}

fn component_count_without_pair(adjacency: &[[bool; MAX_N]; MAX_N], n: usize, a: usize, b: usize) -> usize {
    let mut seen = [false; MAX_N];
    let mut count = 0usize;
    let mut queue = [0usize; MAX_N];
    for start in 0..n {
        if start == a || start == b || seen[start] { continue; }
        count += 1; seen[start] = true; queue[0] = start;
        let (mut head, mut tail) = (0usize, 1usize);
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..n {
                if v != a && v != b && adjacency[u][v] && !seen[v] {
                    seen[v] = true; queue[tail] = v; tail += 1;
                }
            }
        }
    }
    count
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > MAX_INPUT { return -1; }
    let (n64, m64) = (values[0], values[1]);
    if !(3..=MAX_N as i64).contains(&n64) || !(3..=MAX_M as i64).contains(&m64) { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    if values.len() != 2 + n + 2 * m { return -1; }
    let mut weights = [0i64; MAX_N];
    for v in 0..n { weights[v] = values[2 + v]; if !(0..=1_000_000).contains(&weights[v]) { return -1; } }
    let mut adjacency = [[false; MAX_N]; MAX_N];
    let mut pieces = [Piece::default(); MAX_PIECES];
    pieces[0].edge_count = m;
    let offset = 2 + n;
    for e in 0..m {
        let (a, b) = (values[offset + 2 * e], values[offset + 2 * e + 1]);
        if a < 0 || a >= n as i64 || b < 0 || b >= n as i64 || a == b { return -1; }
        let (u, v) = (a as usize, b as usize);
        if adjacency[u][v] { return -1; }
        adjacency[u][v] = true; adjacency[v][u] = true;
        pieces[0].edges[e] = EdgeRef { u, v, pair_id: -1, real: true };
    }
    for removed in -1..n as i32 { if !connected_without(&adjacency, n, removed) { return -1; } }

    let mut piece_count = 1usize;
    let mut split_count = 0usize;
    let mut pair_u = [0usize; MAX_SPLITS]; let mut pair_v = [0usize; MAX_SPLITS];
    let mut is_leaf = [false; MAX_PIECES];
    let mut index = 0usize;
    while index < piece_count {
        let Some((u, v, left_edge)) = find_split(&pieces[index], n) else { is_leaf[index] = true; index += 1; continue; };
        if split_count >= MAX_SPLITS || piece_count + 2 > MAX_PIECES { return -1; }
        let left_index = piece_count; let right_index = piece_count + 1; piece_count += 2;
        let mut left = Piece::default(); let mut right = Piece::default();
        for e in 0..pieces[index].edge_count {
            if left_edge[e] { left.edges[left.edge_count] = pieces[index].edges[e]; left.edge_count += 1; }
            else { right.edges[right.edge_count] = pieces[index].edges[e]; right.edge_count += 1; }
        }
        let pair_id = split_count as i32; split_count += 1; pair_u[pair_id as usize] = u; pair_v[pair_id as usize] = v;
        left.edges[left.edge_count] = EdgeRef { u, v, pair_id, real: false }; left.edge_count += 1;
        right.edges[right.edge_count] = EdgeRef { u, v, pair_id, real: false }; right.edge_count += 1;
        if left.edge_count < 3 || right.edge_count < 3 { return -1; }
        pieces[left_index] = left; pieces[right_index] = right; index += 1;
    }

    let mut kind = [0i32; MAX_PIECES];
    let mut first_leaf = [usize::MAX; MAX_SPLITS]; let mut second_leaf = [usize::MAX; MAX_SPLITS];
    let mut occurrences = [0usize; MAX_SPLITS];
    let mut parent = [0usize; MAX_PIECES];
    for p in 0..piece_count { parent[p] = p; if is_leaf[p] { kind[p] = piece_kind(&pieces[p]); } }
    for p in 0..piece_count { if is_leaf[p] {
        for edge in pieces[p].edges.iter().take(pieces[p].edge_count) {
            if edge.real { continue; }
            if edge.pair_id < 0 || edge.pair_id as usize >= split_count { return -1; }
            let id = edge.pair_id as usize; occurrences[id] += 1;
            if occurrences[id] == 1 { first_leaf[id] = p; } else if occurrences[id] == 2 { second_leaf[id] = p; } else { return -1; }
        }
    }}
    for id in 0..split_count {
        if occurrences[id] != 2 || first_leaf[id] == second_leaf[id] { return -1; }
        let (a, b) = (first_leaf[id], second_leaf[id]);
        if kind[a] == kind[b] && (kind[a] == KIND_S || kind[a] == KIND_P) { unite(&mut parent, a, b); }
    }

    let mut candidate = [[false; MAX_N]; MAX_N];
    for id in 0..split_count { candidate[pair_u[id]][pair_v[id]] = true; }
    for leaf in 0..piece_count { if is_leaf[leaf] && find_root(&mut parent, leaf) == leaf {
        if kind[leaf] == KIND_S {
            let mut in_group = [false; MAX_N]; let mut skeleton = [[false; MAX_N]; MAX_N];
            for member in 0..piece_count { if is_leaf[member] && find_root(&mut parent, member) == leaf {
                for edge in pieces[member].edges.iter().take(pieces[member].edge_count) {
                    if !edge.real && find_root(&mut parent, first_leaf[edge.pair_id as usize]) == leaf
                        && find_root(&mut parent, second_leaf[edge.pair_id as usize]) == leaf { continue; }
                    in_group[edge.u] = true; in_group[edge.v] = true;
                    skeleton[edge.u][edge.v] = true; skeleton[edge.v][edge.u] = true;
                }
            }}
            for u in 0..n { for v in (u + 1)..n { if in_group[u] && in_group[v] && !skeleton[u][v] { candidate[u][v] = true; } }}
        } else if kind[leaf] == KIND_P {
            let mut first = usize::MAX; let mut second = usize::MAX;
            for member in 0..piece_count { if is_leaf[member] && find_root(&mut parent, member) == leaf {
                for edge in pieces[member].edges.iter().take(pieces[member].edge_count) {
                    for endpoint in [edge.u, edge.v] {
                        if first == usize::MAX { first = endpoint; }
                        else if endpoint != first && second == usize::MAX { second = endpoint; }
                        else if endpoint != first && endpoint != second { return -1; }
                    }
                }
            }}
            if first == usize::MAX || second == usize::MAX { return -1; }
            let (u, v) = if first < second { (first, second) } else { (second, first) };
            candidate[u][v] = true;
        }
    }}

    let mut total = 0i64;
    for u in 0..n { for v in (u + 1)..n { if candidate[u][v] {
        let components = component_count_without_pair(&adjacency, n, u, v);
        if components > 1 {
            let term = (weights[u] % MODULUS) * (weights[v] % MODULUS) % MODULUS;
            total = (total + term * (components as i64 - 1)) % MODULUS;
        }
    }}}
    total
}

#[no_mangle]
pub unsafe extern "C" fn two_vertex_cuts_spqr(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
