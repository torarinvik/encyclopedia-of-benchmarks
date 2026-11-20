use std::slice;

const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const INPUT_MAX: usize = 55;
const OUTPUT_MAX: usize = 128;

#[derive(Clone)]
struct Graph {
    n: usize, k: usize, b: usize, m: usize, f: usize, center: usize, outer_id: usize,
    outer: [usize; N], degree: [usize; N], rotation: [[usize; N]; N],
    permutation: [usize; N], adjacent: [[bool; N]; N], edges: [(usize, usize); M],
    face_length: [usize; F], faces: [[usize; N]; F], dart_face: [[i32; N]; N],
}

impl Graph {
    fn connected_without(&self, removed_a: Option<usize>, removed_b: Option<usize>) -> bool {
        let mut start = None;
        let mut expected = 0usize;
        for v in 0..self.n {
            if Some(v) != removed_a && Some(v) != removed_b {
                expected += 1;
                if start.is_none() { start = Some(v); }
            }
        }
        if expected <= 1 { return true; }
        let mut seen = [false; N];
        let mut stack = [0usize; N];
        let mut top = 1usize;
        let mut count = 0usize;
        seen[start.unwrap()] = true;
        stack[0] = start.unwrap();
        while top > 0 {
            top -= 1;
            let u = stack[top];
            count += 1;
            for v in 0..self.n {
                if Some(v) != removed_a && Some(v) != removed_b && self.adjacent[u][v] && !seen[v] {
                    seen[v] = true;
                    stack[top] = v;
                    top += 1;
                }
            }
        }
        count == expected
    }

    fn face_walk(&self, first: usize, second: usize) -> Option<Vec<usize>> {
        let start = (first, second);
        let (mut u, mut v) = start;
        let mut seen = [[false; N]; N];
        let mut cycle = Vec::new();
        for _ in 0..2 * self.m {
            if !self.adjacent[u][v] || seen[u][v] { return None; }
            seen[u][v] = true;
            cycle.push(u);
            let index = self.rotation[v][..self.degree[v]].iter().position(|&x| x == u)?;
            let next = self.rotation[v][(index + 1) % self.degree[v]];
            (u, v) = (v, next);
            if (u, v) == start { return Some(cycle); }
        }
        None
    }
}

fn cyclic_equal(a: &[usize], b: &[usize]) -> bool {
    if a.len() != b.len() { return false; }
    (0..b.len()).any(|shift| (0..a.len()).all(|i| a[i] == b[(i + shift) % b.len()]))
}

fn parse(values: &[i64]) -> Option<Graph> {
    if !(3..=INPUT_MAX).contains(&values.len()) { return None; }
    let n = usize::try_from(values[0]).ok()?;
    let k = usize::try_from(values[1]).ok()?;
    let b = usize::try_from(values[2]).ok()?;
    if !(4..=N).contains(&n) || !(3..=N).contains(&k) || (n - 1) % k != 0
        || !(k..=n).contains(&b) || b % k != 0 {
        return None;
    }
    let mut g = Graph { n, k, b, m: 0, f: 0, center: 0, outer_id: 0,
        outer: [0; N], degree: [0; N], rotation: [[0; N]; N], permutation: [0; N],
        adjacent: [[false; N]; N], edges: [(0, 0); M], face_length: [0; F],
        faces: [[0; N]; F], dart_face: [[-1; N]; N] };
    let mut p = 3usize;
    let mut outer_seen = [false; N];
    for i in 0..b {
        let x = usize::try_from(*values.get(p)?).ok()?;
        p += 1;
        if x >= n || outer_seen[x] { return None; }
        outer_seen[x] = true;
        g.outer[i] = x;
    }
    let mut degree_sum = 0usize;
    for u in 0..n {
        let d = usize::try_from(*values.get(p)?).ok()?;
        p += 1;
        if !(3..n).contains(&d) || p + d > values.len() { return None; }
        g.degree[u] = d;
        degree_sum += d;
        let mut row_seen = [false; N];
        for i in 0..d {
            let v = usize::try_from(values[p + i]).ok()?;
            if v >= n || v == u || row_seen[v] { return None; }
            row_seen[v] = true;
            g.rotation[u][i] = v;
            g.adjacent[u][v] = true;
        }
        p += d;
    }
    if p + n != values.len() || degree_sum % 2 != 0 { return None; }
    let mut perm_seen = [false; N];
    for u in 0..n {
        let v = usize::try_from(values[p + u]).ok()?;
        if v >= n || perm_seen[v] { return None; }
        perm_seen[v] = true;
        g.permutation[u] = v;
    }
    g.m = degree_sum / 2;
    if g.m < n || g.m > 3 * n - 6 || g.m > M { return None; }
    let mut edge_count = 0usize;
    for u in 0..n {
        for v in 0..n {
            if g.adjacent[u][v] != g.adjacent[v][u] { return None; }
            if u < v && g.adjacent[u][v] {
                g.edges[edge_count] = (u, v);
                edge_count += 1;
            }
        }
    }
    if edge_count != g.m || !g.connected_without(None, None) { return None; }
    for u in 0..n {
        if !g.connected_without(Some(u), None) { return None; }
        for v in u + 1..n {
            if !g.connected_without(Some(u), Some(v)) { return None; }
        }
    }

    for edge in 0..g.m {
        let (a, b_edge) = g.edges[edge];
        for (u, v) in [(a, b_edge), (b_edge, a)] {
            if g.dart_face[u][v] >= 0 { continue; }
            if g.f >= F { return None; }
            let cycle = g.face_walk(u, v)?;
            if cycle.len() < 3 || cycle.len() > n || cycle.iter().copied().collect::<std::collections::HashSet<_>>().len() != cycle.len() {
                return None;
            }
            let face_id = g.f;
            for i in 0..cycle.len() {
                let x = cycle[i];
                let y = cycle[(i + 1) % cycle.len()];
                if g.dart_face[x][y] >= 0 { return None; }
                g.faces[face_id][i] = x;
                g.dart_face[x][y] = face_id as i32;
            }
            g.face_length[face_id] = cycle.len();
            g.f += 1;
        }
    }
    if g.f != g.m - g.n + 2 { return None; }
    g.outer_id = (0..g.f).find(|&f| cyclic_equal(&g.outer[..g.b], &g.faces[f][..g.face_length[f]]))?;
    let fixed: Vec<usize> = (0..n).filter(|&v| g.permutation[v] == v).collect();
    if fixed.len() != 1 || outer_seen[fixed[0]] { return None; }
    g.center = fixed[0];
    for vertex in 0..n {
        if vertex == g.center { continue; }
        let mut current = g.permutation[vertex];
        let mut orbit_length = 1usize;
        while current != vertex && orbit_length <= k {
            current = g.permutation[current];
            orbit_length += 1;
        }
        if current != vertex || orbit_length != k { return None; }
    }
    let mut power: [usize; N] = std::array::from_fn(|i| i);
    for exponent in 1..=k {
        let next: [usize; N] = std::array::from_fn(|i| g.permutation[power[i]]);
        let identity = (0..n).all(|i| next[i] == i);
        if identity != (exponent == k) { return None; }
        power = next;
    }
    for u in 0..n {
        let image = g.permutation[u];
        for v in 0..n {
            if g.adjacent[u][v] != g.adjacent[image][g.permutation[v]] { return None; }
        }
        let row: Vec<usize> = g.rotation[u][..g.degree[u]].iter().map(|&v| g.permutation[v]).collect();
        if !cyclic_equal(&row, &g.rotation[image][..g.degree[image]]) { return None; }
    }
    let shift = b / k;
    for i in 0..b {
        if g.permutation[g.outer[i]] != g.outer[(i + shift) % b] { return None; }
    }
    Some(g)
}

fn solve(g: &Graph) -> Option<Vec<i64>> {
    let mut distance = [-1i32; N];
    let mut queue = [0usize; N];
    let (mut head, mut tail) = (0usize, 0usize);
    distance[g.center] = 0;
    queue[tail] = g.center; tail += 1;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..g.n {
            if g.adjacent[u][v] && distance[v] < 0 {
                distance[v] = distance[u] + 1;
                queue[tail] = v; tail += 1;
            }
        }
    }
    let endpoint = *g.outer[..g.b].iter().min_by_key(|&&v| (distance[v], v))?;
    if distance[endpoint] <= 0 { return None; }
    let mut to_end = [-1i32; N];
    head = 0; tail = 0; to_end[endpoint] = 0; queue[tail] = endpoint; tail += 1;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..g.n {
            if g.adjacent[u][v] && to_end[v] < 0 {
                to_end[v] = to_end[u] + 1;
                queue[tail] = v; tail += 1;
            }
        }
    }
    let mut p1 = vec![g.center];
    while *p1.last()? != endpoint {
        let u = *p1.last()?;
        let v = (0..g.n).filter(|&x| g.adjacent[u][x] && to_end[x] == to_end[u] - 1).min()?;
        p1.push(v);
        if p1.len() > N { return None; }
    }
    if p1.len() as i32 - 1 != distance[endpoint] { return None; }
    let p2: Vec<usize> = p1.iter().map(|&v| g.permutation[v]).collect();
    let endpoint2 = *p2.last()?;
    if endpoint2 == endpoint || p1[1..].iter().any(|v| p2[1..].contains(v))
        || p1[1..p1.len() - 1].iter().any(|v| g.outer[..g.b].contains(v))
        || p2[1..p2.len() - 1].iter().any(|v| g.outer[..g.b].contains(v)) { return None; }
    let start = g.outer[..g.b].iter().position(|&v| v == endpoint)?;
    let p0: Vec<usize> = (0..=g.b / g.k).map(|i| g.outer[(start + i) % g.b]).collect();
    if *p0.last()? != endpoint2 { return None; }
    let mut cycle = p1.clone();
    cycle.extend_from_slice(&p0[1..]);
    cycle.extend(p2[..p2.len() - 1].iter().rev().copied());
    if cycle[0] != g.center || *cycle.last()? != g.center
        || cycle[..cycle.len() - 1].iter().copied().collect::<std::collections::HashSet<_>>().len() != cycle.len() - 1 {
        return None;
    }
    let mut cut = [[false; N]; N];
    for pair in cycle.windows(2) { cut[pair[0]][pair[1]] = true; cut[pair[1]][pair[0]] = true; }
    let seed = usize::try_from(g.dart_face[p0[1]][p0[0]]).ok()?;
    if seed == g.outer_id { return None; }
    let mut dual = [[false; F]; F];
    for &(u, v) in &g.edges[..g.m] {
        if cut[u][v] { continue; }
        let a = usize::try_from(g.dart_face[u][v]).ok()?;
        let b = usize::try_from(g.dart_face[v][u]).ok()?;
        dual[a][b] = true; dual[b][a] = true;
    }
    let mut inside = [false; F];
    head = 0; tail = 0; queue[tail] = seed; tail += 1; inside[seed] = true;
    while head < tail {
        let f = queue[head]; head += 1;
        for other in 0..g.f {
            if dual[f][other] && !inside[other] {
                inside[other] = true; queue[tail] = other; tail += 1;
            }
        }
    }
    if inside[g.outer_id] { return None; }
    let mut vertices = [false; N];
    for &v in &cycle[..cycle.len() - 1] { vertices[v] = true; }
    for f in 0..g.f {
        if inside[f] {
            for i in 0..g.face_length[f] { vertices[g.faces[f][i]] = true; }
        }
    }
    let vertex_mask = (0..g.n).filter(|&v| vertices[v]).fold(0i64, |mask, v| mask | (1i64 << v));
    let edge_mask = g.edges[..g.m].iter().enumerate().filter(|(_, &(u, v))| vertices[u] && vertices[v])
        .fold(0i64, |mask, (i, _)| mask | (1i64 << i));
    let mut words = vec![p1.len() as i64]; words.extend(p1.iter().map(|&x| x as i64));
    words.push(p2.len() as i64); words.extend(p2.iter().map(|&x| x as i64));
    words.push(p0.len() as i64); words.extend(p0.iter().map(|&x| x as i64));
    words.push(vertex_mask); words.push(edge_mask);
    Some(words)
}

fn write_i64_le(out: &mut [u8], at: usize, value: i64) {
    out[at..at + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn symmetric_drawing_cyclic_wedge(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > INPUT_MAX { return -1; }
    let values = slice::from_raw_parts(input, input_length);
    let Some(graph) = parse(values) else { return -1; };
    let Some(words) = solve(&graph) else { return -1; };
    let bytes = words.len() * 8;
    if bytes > OUTPUT_MAX { return -1; }
    if output.is_null() || output_capacity < bytes { return -2; }
    let mut temporary = [0u8; OUTPUT_MAX];
    for (i, word) in words.iter().enumerate() { write_i64_le(&mut temporary, i * 8, *word); }
    std::ptr::copy_nonoverlapping(temporary.as_ptr(), output, bytes);
    bytes as i64
}
