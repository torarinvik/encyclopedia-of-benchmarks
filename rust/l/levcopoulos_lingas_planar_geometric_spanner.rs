use std::cmp::Ordering;

const MAX_N: usize = 8;
const MAX_EDGES: usize = 18;
const MAX_FACES: usize = 16;
const MAX_DARTS: usize = 2 * (MAX_N - 1);
const MAX_STACK: usize = 64;
const MAX_INPUT: usize = 55;

#[derive(Default)]
struct State {
    x: [i64; MAX_N],
    y: [i64; MAX_N],
    edge_u: [usize; MAX_EDGES],
    edge_v: [usize; MAX_EDGES],
    edge_count: usize,
    face_a: [usize; MAX_FACES],
    face_b: [usize; MAX_FACES],
    face_c: [usize; MAX_FACES],
    face_count: usize,
    rotation: [[usize; MAX_N]; MAX_N],
    degree: [usize; MAX_N],
    tree_rotation: [[usize; MAX_N]; MAX_N],
    tree_degree: [usize; MAX_N],
    contour: [[usize; 2]; MAX_DARTS],
    contour_len: usize,
    stack: [[usize; 2]; MAX_STACK],
    stack_len: usize,
    weight: [[f64; MAX_N]; MAX_N],
    hull: [bool; MAX_N],
    tree: [[bool; MAX_N]; MAX_N],
    kept: [[bool; MAX_N]; MAX_N],
}

fn orient(s: &State, a: usize, b: usize, c: usize) -> i64 {
    (s.x[b] - s.x[a]) * (s.y[c] - s.y[a]) - (s.y[b] - s.y[a]) * (s.x[c] - s.x[a])
}

fn incircle(s: &State, a: usize, b: usize, c: usize, p: usize) -> i64 {
    let (ax, ay) = (s.x[a] - s.x[p], s.y[a] - s.y[p]);
    let (bx, by) = (s.x[b] - s.x[p], s.y[b] - s.y[p]);
    let (cx, cy) = (s.x[c] - s.x[p], s.y[c] - s.y[p]);
    let d = (ax * ax + ay * ay) * (bx * cy - by * cx)
        - (bx * bx + by * by) * (ax * cy - ay * cx)
        + (cx * cx + cy * cy) * (ax * by - ay * bx);
    if orient(s, a, b, c) > 0 { d } else { -d }
}

fn dist2(s: &State, a: usize, b: usize) -> i64 {
    let dx = s.x[a] - s.x[b];
    let dy = s.y[a] - s.y[b];
    dx * dx + dy * dy
}

fn sort3(mut a: usize, mut b: usize, mut c: usize) -> (usize, usize, usize) {
    if a > b { std::mem::swap(&mut a, &mut b); }
    if b > c { std::mem::swap(&mut b, &mut c); }
    if a > b { std::mem::swap(&mut a, &mut b); }
    (a, b, c)
}

fn is_face(s: &State, a: usize, b: usize, c: usize) -> bool {
    let (a, b, c) = sort3(a, b, c);
    (0..s.face_count).any(|i| (s.face_a[i], s.face_b[i], s.face_c[i]) == (a, b, c))
}

fn angle_cmp(s: &State, origin: usize, a: usize, b: usize) -> Ordering {
    let (ax, ay) = (s.x[a] - s.x[origin], s.y[a] - s.y[origin]);
    let (bx, by) = (s.x[b] - s.x[origin], s.y[b] - s.y[origin]);
    let ah = if ay > 0 || (ay == 0 && ax >= 0) { 0 } else { 1 };
    let bh = if by > 0 || (by == 0 && bx >= 0) { 0 } else { 1 };
    ah.cmp(&bh).then_with(|| {
        let cross = ax * by - ay * bx;
        if cross > 0 { Ordering::Less } else if cross < 0 { Ordering::Greater } else { a.cmp(&b) }
    })
}

fn sort_neighbors(s: &State, row: &mut [usize; MAX_N], count: usize, origin: usize) {
    for i in 1..count {
        let key = row[i];
        let mut j = i;
        while j > 0 && angle_cmp(s, origin, key, row[j - 1]) == Ordering::Less {
            row[j] = row[j - 1];
            j -= 1;
        }
        row[j] = key;
    }
}

fn cw_next(s: &State, u: usize, v: usize) -> Option<(usize, usize)> {
    let row = &s.rotation[v];
    for i in 0..s.degree[v] {
        if row[i] == u { return Some((v, row[(i + s.degree[v] - 1) % s.degree[v]])); }
    }
    None
}

fn cw_tree_next(s: &State, u: usize, v: usize) -> Option<(usize, usize)> {
    let row = &s.tree_rotation[v];
    for i in 0..s.tree_degree[v] {
        if row[i] == u { return Some((v, row[(i + s.tree_degree[v] - 1) % s.tree_degree[v]])); }
    }
    None
}

fn contour_find(s: &State, u: usize, v: usize) -> Option<usize> {
    (0..s.contour_len).find(|&i| s.contour[i] == [u, v])
}

fn canonicalize(s: &mut State) {
    if s.contour_len == 0 { return; }
    let first = (0..s.contour_len).min_by_key(|&i| s.contour[i]).unwrap_or(0);
    let mut rotated = [[0usize; 2]; MAX_DARTS];
    for i in 0..s.contour_len { rotated[i] = s.contour[(first + i) % s.contour_len]; }
    s.contour = rotated;
}

fn eligible(s: &State, u: usize, v: usize) -> bool {
    let Some(i) = contour_find(s, u, v) else { return false; };
    if s.hull[v] || s.contour_len < 3 { return false; }
    let next = (i + 1) % s.contour_len;
    let Some(cw) = cw_next(s, u, v) else { return false; };
    s.contour[next] == [cw.0, cw.1] && is_face(s, u, v, cw.1)
}

fn push_candidate(s: &mut State, u: usize, v: usize) -> bool {
    if !eligible(s, u, v) { return true; }
    if s.stack_len >= MAX_STACK { return false; }
    s.stack[s.stack_len] = [u, v];
    s.stack_len += 1;
    true
}

fn parse(s: &mut State, input: &[i64]) -> Option<usize> {
    if input.len() < 14 || input.len() > MAX_INPUT { return None; }
    let n = usize::try_from(input[0]).ok()?;
    if !(3..=MAX_N).contains(&n) { return None; }
    let m_at = 1 + 2 * n;
    if input.len() <= m_at { return None; }
    let m = usize::try_from(input[m_at]).ok()?;
    if !(3..=MAX_EDGES).contains(&m) || input.len() != m_at + 1 + 2 * m { return None; }
    for i in 0..n {
        s.x[i] = input[1 + 2 * i];
        s.y[i] = input[2 + 2 * i];
        if !(-10..=10).contains(&s.x[i]) || !(-10..=10).contains(&s.y[i]) { return None; }
        for j in 0..i { if s.x[i] == s.x[j] && s.y[i] == s.y[j] { return None; } }
    }
    for a in 0..n { for b in a + 1..n { for c in b + 1..n { if orient(s, a, b, c) == 0 { return None; } } } }
    for a in 0..n { for b in a + 1..n { for c in b + 1..n { for d in c + 1..n { if incircle(s, a, b, c, d) == 0 { return None; } } } } }

    s.edge_count = m;
    let mut supplied = [[false; MAX_N]; MAX_N];
    for i in 0..m {
        let u = usize::try_from(input[m_at + 1 + 2 * i]).ok()?;
        let v = usize::try_from(input[m_at + 2 + 2 * i]).ok()?;
        if u >= v || v >= n || (i > 0 && (u, v) <= (s.edge_u[i - 1], s.edge_v[i - 1])) { return None; }
        s.edge_u[i] = u; s.edge_v[i] = v;
        supplied[u][v] = true; supplied[v][u] = true;
    }
    let mut expected = [[false; MAX_N]; MAX_N];
    for a in 0..n { for b in a + 1..n { for c in b + 1..n {
        let mut tri = [a, b, c];
        if orient(s, tri[0], tri[1], tri[2]) < 0 { tri.swap(1, 2); }
        let empty = (0..n).all(|p| p == tri[0] || p == tri[1] || p == tri[2] || incircle(s, tri[0], tri[1], tri[2], p) <= 0);
        if empty {
            if s.face_count >= MAX_FACES { return None; }
            let (fa, fb, fc) = sort3(a, b, c);
            let k = s.face_count; s.face_a[k] = fa; s.face_b[k] = fb; s.face_c[k] = fc; s.face_count += 1;
            for (u, v) in [(a,b),(b,c),(a,c)] { expected[u][v] = true; expected[v][u] = true; }
        }
    } } }
    for a in 0..n { for b in a + 1..n { if supplied[a][b] != expected[a][b] { return None; } } }
    for a in 0..n { for b in a + 1..n {
        let mut positive = false; let mut negative = false;
        for p in 0..n { if p != a && p != b { let side = orient(s, a, b, p); positive |= side > 0; negative |= side < 0; } }
        if !(positive && negative) { s.hull[a] = true; s.hull[b] = true; }
    } }
    for i in 0..m {
        let (u, v) = (s.edge_u[i], s.edge_v[i]);
        s.rotation[u][s.degree[u]] = v; s.degree[u] += 1;
        s.rotation[v][s.degree[v]] = u; s.degree[v] += 1;
    }
    for v in 0..n {
        let mut row = s.rotation[v];
        sort_neighbors(s, &mut row, s.degree[v], v);
        s.rotation[v] = row;
    }
    Some(n)
}

fn build_mst_contour(s: &mut State, n: usize) -> bool {
    let mut order = [0usize; MAX_EDGES];
    for i in 0..s.edge_count { order[i] = i; }
    order[..s.edge_count].sort_by_key(|&i| (dist2(s, s.edge_u[i], s.edge_v[i]), s.edge_u[i], s.edge_v[i]));
    let mut parent = [0usize; MAX_N]; let mut size = [1usize; MAX_N];
    for (i, p) in parent.iter_mut().enumerate() { *p = i; }
    let mut chosen = 0;
    for &e in &order[..s.edge_count] {
        let (u, v) = (s.edge_u[e], s.edge_v[e]);
        let (mut a, mut b) = (u, v);
        while parent[a] != a { parent[a] = parent[parent[a]]; a = parent[a]; }
        while parent[b] != b { parent[b] = parent[parent[b]]; b = parent[b]; }
        if a == b { continue; }
        if size[a] < size[b] { std::mem::swap(&mut a, &mut b); }
        parent[b] = a; size[a] += size[b];
        s.tree[u][v] = true; s.tree[v][u] = true; s.kept[u][v] = true; s.kept[v][u] = true;
        let du = s.tree_degree[u]; s.tree_rotation[u][du] = v; s.tree_degree[u] += 1;
        let dv = s.tree_degree[v]; s.tree_rotation[v][dv] = u; s.tree_degree[v] += 1;
        chosen += 1;
    }
    if chosen != n - 1 { return false; }
    for v in 0..n {
        let mut row = s.tree_rotation[v];
        sort_neighbors(s, &mut row, s.tree_degree[v], v);
        s.tree_rotation[v] = row;
    }
    for i in 0..s.edge_count {
        let (u, v) = (s.edge_u[i], s.edge_v[i]);
        let w = (dist2(s, u, v) as f64).sqrt(); s.weight[u][v] = w; s.weight[v][u] = w;
    }
    let mut first = (MAX_N, MAX_N);
    for u in 0..n { for v in 0..n { if s.tree[u][v] && (u, v) < first { first = (u, v); } } }
    if first.0 == MAX_N { return false; }
    s.contour[0] = [first.0, first.1]; s.contour_len = 1;
    let expected = 2 * (n - 1);
    while s.contour_len < expected {
        let prev = s.contour[s.contour_len - 1];
        let Some(next) = cw_tree_next(s, prev[0], prev[1]) else { return false; };
        if next == first { break; }
        if s.contour[..s.contour_len].contains(&[next.0, next.1]) { return false; }
        s.contour[s.contour_len] = [next.0, next.1]; s.contour_len += 1;
    }
    if s.contour_len != expected { return false; }
    cw_tree_next(s, s.contour[s.contour_len - 1][0], s.contour[s.contour_len - 1][1]) == Some(first)
}

fn run_algorithm(s: &mut State, n: usize) -> Option<(usize, usize)> {
    for i in 0..s.contour_len { let dart = s.contour[i]; if !push_candidate(s, dart[0], dart[1]) { return None; } }
    let mut absorbed = 0usize;
    let mut steps = 0usize;
    while s.stack_len > 0 && steps < 2 * MAX_EDGES {
        s.stack_len -= 1;
        let (v, w) = (s.stack[s.stack_len][0], s.stack[s.stack_len][1]);
        if !eligible(s, v, w) { continue; }
        let at = contour_find(s, v, w)?;
        let next_at = (at + 1) % s.contour_len;
        let u = s.contour[next_at][1];
        let path_weight = s.weight[v][w] + s.weight[w][u];
        let chord = (dist2(s, v, u) as f64).sqrt();
        if path_weight > 2.0 * chord { s.kept[v][u] = true; s.kept[u][v] = true; }
        else { s.weight[v][u] = path_weight; }
        if next_at == 0 {
            for i in 0..s.contour_len - 1 { s.contour[i] = s.contour[i + 1]; }
            s.contour_len -= 1; s.contour[s.contour_len - 1] = [v, u];
        } else {
            s.contour[at] = [v, u];
            for i in next_at..s.contour_len - 1 { s.contour[i] = s.contour[i + 1]; }
            s.contour_len -= 1;
        }
        canonicalize(s); absorbed += 1; steps += 1;
        let chord_at = contour_find(s, v, u)?;
        if !push_candidate(s, v, u) { return None; }
        let left_at = (chord_at + s.contour_len - 1) % s.contour_len;
        let left = s.contour[left_at];
        if !push_candidate(s, left[0], left[1]) { return None; }
    }
    if steps >= 2 * MAX_EDGES && s.stack_len > 0 { return None; }
    let mut shortcuts = 0;
    for u in 0..n { for v in u + 1..n { if s.kept[u][v] && !s.tree[u][v] { shortcuts += 1; } } }
    Some((absorbed, shortcuts))
}

#[no_mangle]
pub unsafe extern "C" fn levcopoulos_lingas_planar_geometric_spanner(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 14 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut s = State::default();
    let Some(n) = parse(&mut s, values) else { return -1; };
    if !build_mst_contour(&mut s, n) { return -1; }
    let Some((absorbed, shortcuts)) = run_algorithm(&mut s, n) else { return -1; };
    let mut words = [0i64; 3 + 2 * MAX_EDGES];
    words[0] = absorbed as i64; words[1] = shortcuts as i64;
    let mut count = 3;
    for u in 0..n { for v in u + 1..n { if s.kept[u][v] { words[count] = u as i64; words[count + 1] = v as i64; words[2] += 1; count += 2; } } }
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for (i, word) in words[..count].iter().enumerate() {
        let encoded = word.to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(i * 8), 8);
    }
    bytes as i64
}
