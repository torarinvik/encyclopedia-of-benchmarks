const MAX_N: usize = 8;
const MAX_INPUT: usize = 49;
const MAX_DARTS: usize = 48;

#[derive(Clone, Copy)]
struct Embedding {
    n: usize,
    u: usize,
    v: usize,
    w: usize,
    degree: [usize; MAX_N],
    rotation: [[usize; MAX_N]; MAX_N],
    adjacent: [[bool; MAX_N]; MAX_N],
}

impl Default for Embedding {
    fn default() -> Self {
        Self { n: 0, u: 0, v: 0, w: 0, degree: [0; MAX_N],
               rotation: [[0; MAX_N]; MAX_N], adjacent: [[false; MAX_N]; MAX_N] }
    }
}

fn next_active(g: &Embedding, active: &[bool; MAX_N], source: usize, target: usize) -> Option<usize> {
    let mut source_position = None;
    let mut remaining = 0;
    for index in 0..g.degree[target] {
        let neighbor = g.rotation[target][index];
        if active[neighbor] {
            remaining += 1;
            if neighbor == source { source_position = Some(index); }
        }
    }
    if remaining < 2 { return None; }
    let start = source_position?;
    for step in 1..=g.degree[target] {
        let neighbor = g.rotation[target][(start + step) % g.degree[target]];
        if active[neighbor] { return Some(neighbor); }
    }
    None
}

fn face_cycle(g: &Embedding, active: &[bool; MAX_N], first: usize, second: usize,
              cycle: &mut [usize; MAX_DARTS]) -> Option<usize> {
    let mut seen = [[false; MAX_N]; MAX_N];
    let (mut source, mut target) = (first, second);
    let mut length = 0;
    for _ in 0..MAX_DARTS {
        if source >= g.n || target >= g.n || !active[source] || !active[target] ||
            !g.adjacent[source][target] || seen[source][target] { return None; }
        seen[source][target] = true;
        cycle[length] = source;
        length += 1;
        let following = next_active(g, active, source, target)?;
        (source, target) = (target, following);
        if source == first && target == second { return Some(length); }
    }
    None
}

fn parse_embedding(values: &[i64]) -> Option<Embedding> {
    if !(4..=MAX_INPUT).contains(&values.len()) { return None; }
    let n = usize::try_from(values[0]).ok()?;
    if !(3..=MAX_N).contains(&n) { return None; }
    let u = usize::try_from(values[1]).ok()?;
    let v = usize::try_from(values[2]).ok()?;
    let w = usize::try_from(values[3]).ok()?;
    if u >= n || v >= n || w >= n || u == v || u == w || v == w { return None; }
    let mut g = Embedding { n, u, v, w, ..Embedding::default() };
    let mut offset = 4;
    let mut degree_sum = 0;
    for vertex in 0..n {
        let degree = usize::try_from(*values.get(offset)?).ok()?;
        offset += 1;
        if degree < 2 || degree >= n || offset + degree > values.len() { return None; }
        let mut row_seen = [false; MAX_N];
        g.degree[vertex] = degree;
        degree_sum += degree;
        for rank in 0..degree {
            let neighbor = usize::try_from(values[offset + rank]).ok()?;
            if neighbor >= n || neighbor == vertex || row_seen[neighbor] { return None; }
            row_seen[neighbor] = true;
            g.rotation[vertex][rank] = neighbor;
            g.adjacent[vertex][neighbor] = true;
        }
        offset += degree;
    }
    if offset != values.len() || degree_sum != 6 * n - 12 { return None; }
    let mut edge_count = 0;
    for a in 0..n { for b in 0..n {
        if g.adjacent[a][b] != g.adjacent[b][a] { return None; }
        if a < b && g.adjacent[a][b] { edge_count += 1; }
    }}
    if edge_count != 3 * n - 6 { return None; }
    let mut reached = [false; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut top = 1;
    let mut reached_count = 0;
    reached[0] = true;
    while top > 0 {
        top -= 1;
        let vertex = stack[top];
        reached_count += 1;
        for neighbor in 0..n {
            if g.adjacent[vertex][neighbor] && !reached[neighbor] {
                reached[neighbor] = true;
                stack[top] = neighbor;
                top += 1;
            }
        }
    }
    if reached_count != n { return None; }

    let active = [true; MAX_N];
    let mut seen_dart = [[false; MAX_N]; MAX_N];
    let (mut face_count, mut visited_darts) = (0, 0);
    for source in 0..n { for target in 0..n {
        if !g.adjacent[source][target] || seen_dart[source][target] { continue; }
        let mut cycle = [0usize; MAX_DARTS];
        let length = face_cycle(&g, &active, source, target, &mut cycle)?;
        if length != 3 { return None; }
        face_count += 1;
        for i in 0..length {
            let a = cycle[i];
            let b = cycle[(i + 1) % length];
            if seen_dart[a][b] { return None; }
            seen_dart[a][b] = true;
            visited_darts += 1;
        }
    }}
    if face_count != 2 * n - 4 || visited_darts != 6 * n - 12 { return None; }
    let mut outer = [0usize; MAX_DARTS];
    let length = face_cycle(&g, &active, u, v, &mut outer)?;
    if length != 3 || [outer[0], outer[1], outer[2]] != [u, v, w] { return None; }
    Some(g)
}

fn boundary_path(g: &Embedding, active: &[bool; MAX_N], path: &mut [usize; MAX_N]) -> Option<usize> {
    let mut cycle = [0usize; MAX_DARTS];
    let length = face_cycle(g, active, g.u, g.v, &mut cycle)?;
    if length < 3 { return None; }
    let mut count = 1;
    path[0] = g.u;
    for index in (2..length).rev() {
        path[count] = cycle[index];
        count += 1;
    }
    path[count] = g.v;
    Some(count + 1)
}

fn peel_choice(g: &Embedding, path: &[usize; MAX_N], length: usize) -> Option<usize> {
    let mut chord = [[false; MAX_N]; MAX_N];
    let mut chord_count = 0;
    for left in 0..length { for right in left + 2..length {
        if left == 0 && right + 1 == length { continue; }
        if g.adjacent[path[left]][path[right]] {
            chord[left][right] = true;
            chord_count += 1;
        }
    }}
    let mut eligible = [false; MAX_N];
    if chord_count == 0 {
        for index in 1..length - 1 { eligible[path[index]] = true; }
    } else {
        for left in 0..length { for right in left + 2..length {
            if !chord[left][right] { continue; }
            let mut minimal = true;
            for inner_left in left..right { for inner_right in inner_left + 2..=right {
                if chord[inner_left][inner_right] && (inner_left != left || inner_right != right) {
                    minimal = false;
                }
            }}
            if minimal { for index in left + 1..right { eligible[path[index]] = true; } }
        }}
    }
    (0..g.n).filter(|&vertex| eligible[vertex]).min()
}

fn peel_contains(g: &Embedding, path: &[usize; MAX_N], length: usize, candidate: usize) -> bool {
    let mut chord = [[false; MAX_N]; MAX_N];
    let mut chord_count = 0;
    for left in 0..length { for right in left + 2..length {
        if left == 0 && right + 1 == length { continue; }
        if g.adjacent[path[left]][path[right]] {
            chord[left][right] = true;
            chord_count += 1;
        }
    }}
    let mut eligible = [false; MAX_N];
    if chord_count == 0 {
        for index in 1..length - 1 { eligible[path[index]] = true; }
    } else {
        for left in 0..length { for right in left + 2..length {
            if !chord[left][right] { continue; }
            let mut minimal = true;
            for a in left..right { for b in a + 2..=right {
                if chord[a][b] && (a != left || b != right) { minimal = false; }
            }}
            if minimal { for index in left + 1..right { eligible[path[index]] = true; } }
        }}
    }
    eligible[candidate]
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn canonical_order_schnyder_realizer(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(6..=57).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let Ok(n) = usize::try_from(values[0]) else { return -1; };
    if !(3..=MAX_N).contains(&n) || length < n + 4 { return -1; }
    let graph_length = length - n;
    let Some(g) = parse_embedding(&values[..graph_length]) else { return -1; };
    if g.n != n { return -1; }
    let mut order = [0usize; MAX_N];
    let mut order_seen = [false; MAX_N];
    for i in 0..n {
        let Ok(vertex) = usize::try_from(values[graph_length + i]) else { return -1; };
        if vertex >= n || order_seen[vertex] { return -1; }
        order[i] = vertex;
        order_seen[vertex] = true;
    }
    if order[0] != g.u || order[1] != g.v || order[n - 1] != g.w { return -1; }
    let mut active = [false; MAX_N];
    active[..n].fill(true);
    if n > 3 {
        active[g.w] = false;
        let mut path = [0usize; MAX_N];
        let Some(mut path_length) = boundary_path(&g, &active, &mut path) else { return -1; };
        for i in (3..n - 1).rev() {
            let candidate = order[i];
            if candidate == g.u || candidate == g.v || !active[candidate] ||
                !peel_contains(&g, &path, path_length, candidate) { return -1; }
            active[candidate] = false;
            let Some(next_length) = boundary_path(&g, &active, &mut path) else { return -1; };
            path_length = next_length;
        }
        if path_length != 3 || path[0] != g.u || path[1] != order[2] || path[2] != g.v { return -1; }
    } else if order[2] != g.w { return -1; }

    let mut position = [0usize; MAX_N];
    for i in 0..n { position[order[i]] = i; }
    let mut words = [0i64; 1 + 4 * (MAX_N - 3)];
    let mut count = 0;
    words[count] = n as i64;
    count += 1;
    for rank in 2..n - 1 {
        let vertex = order[rank];
        let (left, right) = if rank == 2 {
            if !g.adjacent[vertex][g.u] || !g.adjacent[vertex][g.v] { return -1; }
            (g.u, g.v)
        } else {
            let mut prefix = [false; MAX_N];
            for &earlier in &order[..rank] { prefix[earlier] = true; }
            let mut boundary = [0usize; MAX_N];
            let Some(boundary_length) = boundary_path(&g, &prefix, &mut boundary) else { return -1; };
            let mut first = None;
            let mut last = None;
            let mut seen_gap = false;
            let mut boundary_count = 0;
            for &node in &boundary[..boundary_length] {
                if g.adjacent[vertex][node] {
                    if seen_gap { return -1; }
                    if first.is_none() { first = Some(node); }
                    last = Some(node);
                    boundary_count += 1;
                } else if first.is_some() { seen_gap = true; }
            }
            let predecessor_count = order[..rank].iter().filter(|&&node| g.adjacent[vertex][node]).count();
            if boundary_count < 2 || boundary_count != predecessor_count { return -1; }
            let (Some(first), Some(last)) = (first, last) else { return -1; };
            (first, last)
        };
        let mut successor = None;
        for other in 0..n {
            if position[other] > rank && g.adjacent[vertex][other] &&
                successor.map_or(true, |old| position[other] > position[old]) { successor = Some(other); }
        }
        let Some(successor) = successor else { return -1; };
        for value in [vertex, left, right, successor] {
            words[count] = value as i64;
            count += 1;
        }
    }
    let required = 8 * count;
    if output.is_null() || capacity < required { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, required);
    for index in 0..count { write_i64_le(bytes, 8 * index, words[index]); }
    required as i64
}
