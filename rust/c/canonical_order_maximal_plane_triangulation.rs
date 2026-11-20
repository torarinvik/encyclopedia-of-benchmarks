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

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn canonical_order_maximal_plane_triangulation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let Some(g) = parse_embedding(values) else { return -1; };
    let mut active = [false; MAX_N];
    active[..g.n].fill(true);
    let mut removals = [0usize; MAX_N];
    let mut removed = 0;
    if g.n > 3 {
        active[g.w] = false;
        removals[removed] = g.w;
        removed += 1;
        let mut path = [0usize; MAX_N];
        let Some(mut path_length) = boundary_path(&g, &active, &mut path) else { return -1; };
        let mut active_count = g.n - 1;
        while active_count > 3 {
            let Some(choice) = peel_choice(&g, &path, path_length) else { return -1; };
            if choice == g.u || choice == g.v || !active[choice] { return -1; }
            active[choice] = false;
            removals[removed] = choice;
            removed += 1;
            active_count -= 1;
            let Some(next_length) = boundary_path(&g, &active, &mut path) else { return -1; };
            path_length = next_length;
        }
        if path_length != 3 || path[0] != g.u || path[2] != g.v { return -1; }
    }
    let mut words = [0i64; MAX_N + 1];
    words[0] = g.n as i64;
    words[1] = g.u as i64;
    words[2] = g.v as i64;
    let mut count = 3;
    if g.n == 3 {
        words[count] = g.w as i64;
        count += 1;
    } else {
        let third = (0..g.n).find(|&node| active[node] && node != g.u && node != g.v);
        let Some(third) = third else { return -1; };
        words[count] = third as i64;
        count += 1;
        for index in (0..removed).rev() {
            words[count] = removals[index] as i64;
            count += 1;
        }
    }
    if count != g.n + 1 || words[count - 1] != g.w as i64 { return -1; }
    let required = 8 * count;
    if output.is_null() || capacity < required { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, required);
    for index in 0..count { write_i64_le(bytes, 8 * index, words[index]); }
    required as i64
}
