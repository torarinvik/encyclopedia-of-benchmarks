const MIN_N: usize = 3;
const MAX_N: usize = 4;
const MAX_LEN: usize = 10;
const MAX_ANGLES: usize = 12;

#[derive(Clone, Copy, Default)]
struct AngleRef { a: usize, b: usize, c: usize, vertex: usize }
#[derive(Clone, Copy)]
struct Triangle { a: usize, b: usize, c: usize }

fn orient(p: &[(i64, i64); MAX_N], a: usize, b: usize, c: usize) -> i64 {
    (p[b].0 - p[a].0) * (p[c].1 - p[a].1) - (p[b].1 - p[a].1) * (p[c].0 - p[a].0)
}

fn angle_parts(p: &[(i64, i64); MAX_N], angle: AngleRef) -> (i64, i64) {
    let v = [angle.a, angle.b, angle.c];
    let center = v[angle.vertex];
    let mut endpoints = [0usize; 2];
    let mut used = 0;
    for vertex in v {
        if vertex != center { endpoints[used] = vertex; used += 1; }
    }
    let ux = p[endpoints[0]].0 - p[center].0;
    let uy = p[endpoints[0]].1 - p[center].1;
    let vx = p[endpoints[1]].0 - p[center].0;
    let vy = p[endpoints[1]].1 - p[center].1;
    (ux * vx + uy * vy, (ux * ux + uy * uy) * (vx * vx + vy * vy))
}

fn angle_cmp(p: &[(i64, i64); MAX_N], left: AngleRef, right: AngleRef) -> i32 {
    let (d1, z1) = angle_parts(p, left);
    let (d2, z2) = angle_parts(p, right);
    if d1 == 0 || d2 == 0 {
        if d1 == d2 { return 0; }
        if d1 == 0 { return if d2 > 0 { 1 } else { -1 }; }
        return if d1 > 0 { -1 } else { 1 };
    }
    if (d1 < 0) != (d2 < 0) { return if d1 < 0 { 1 } else { -1 }; }
    let lhs = d1 * d1 * z2;
    let rhs = d2 * d2 * z1;
    if lhs == rhs { return 0; }
    if d1 > 0 { if lhs > rhs { -1 } else { 1 } }
    else { if lhs > rhs { 1 } else { -1 } }
}

fn triangle_max(p: &[(i64, i64); MAX_N], t: Triangle) -> AngleRef {
    let mut v = [t.a, t.b, t.c];
    v.sort_unstable();
    let mut best = AngleRef { a: v[0], b: v[1], c: v[2], vertex: 0 };
    for vertex in 1..3 {
        let candidate = AngleRef { a: v[0], b: v[1], c: v[2], vertex };
        if angle_cmp(p, candidate, best) > 0 { best = candidate; }
    }
    best
}

fn triangulation_max(p: &[(i64, i64); MAX_N], triangles: &[Triangle]) -> AngleRef {
    let mut best = triangle_max(p, triangles[0]);
    for triangle in &triangles[1..] {
        let candidate = triangle_max(p, *triangle);
        if angle_cmp(p, candidate, best) > 0 { best = candidate; }
    }
    best
}

fn angle_rank(p: &[(i64, i64); MAX_N], n: usize, target: AngleRef) -> i64 {
    let mut distinct_lower = [AngleRef::default(); MAX_ANGLES];
    let mut distinct_count = 0usize;
    for a in 0..n { for b in a + 1..n { for c in b + 1..n { for vertex in 0..3 {
        let candidate = AngleRef { a, b, c, vertex };
        if angle_cmp(p, candidate, target) >= 0 { continue; }
        let mut seen = false;
        for previous in &distinct_lower[..distinct_count] {
            if angle_cmp(p, candidate, *previous) == 0 { seen = true; break; }
        }
        if !seen { distinct_lower[distinct_count] = candidate; distinct_count += 1; }
    }}}}
    (distinct_count + 1) as i64
}

fn proper_crossing(p: &[(i64, i64); MAX_N], a: usize, b: usize, c: usize, d: usize) -> bool {
    orient(p, a, b, c) * orient(p, a, b, d) < 0 && orient(p, c, d, a) * orient(p, c, d, b) < 0
}

#[no_mangle]
pub unsafe extern "C" fn convex_polygon_minimax_angle_edge_insertion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LEN { return -1; }
    let count = *input;
    if count < MIN_N as i64 || count > MAX_N as i64 { return -1; }
    let n = count as usize;
    if length != 1 + 2 * n { return -1; }
    let mut p = [(0_i64, 0_i64); MAX_N];
    for i in 0..n {
        let x = *input.add(1 + 2 * i);
        let y = *input.add(2 + 2 * i);
        if !(-16..=16).contains(&x) || !(-16..=16).contains(&y) { return -1; }
        for j in 0..i { if p[j] == (x, y) { return -1; } }
        p[i] = (x, y);
    }
    let mut area2 = 0_i64;
    for i in 0..n {
        let next = (i + 1) % n;
        area2 += p[i].0 * p[next].1 - p[i].1 * p[next].0;
    }
    if area2 == 0 { return -1; }
    let orientation = if area2 > 0 { 1_i64 } else { -1_i64 };
    for a in 0..n { for b in a + 1..n { for c in b + 1..n { if orient(&p, a, b, c) == 0 { return -1; } } } }
    for edge in 0..n {
        let next = (edge + 1) % n;
        for vertex in 0..n {
            if vertex != edge && vertex != next && orientation * orient(&p, edge, next, vertex) <= 0 { return -1; }
        }
    }

    let fan = [Triangle { a: 0, b: 1, c: 2 }, Triangle { a: 0, b: 2, c: 3 }];
    let mut worst = if n == 3 {
        triangle_max(&p, Triangle { a: 0, b: 1, c: 2 })
    } else { triangulation_max(&p, &fan) };
    if n == 4 {
        let mut accepted = false;
        for triangle in &fan {
            let vertices = [triangle.a, triangle.b, triangle.c];
            for vertex in 0..3 {
                let candidate = AngleRef { a: vertices[0], b: vertices[1], c: vertices[2], vertex };
                if angle_cmp(&p, candidate, worst) != 0 { continue; }
                let q = vertices[vertex];
                let mut opposite = [0usize; 2];
                let mut used = 0;
                for position in 0..3 {
                    if position != vertex { opposite[used] = vertices[position]; used += 1; }
                }
                let s = (0..4).find(|point| !vertices.contains(point)).unwrap();
                if !proper_crossing(&p, q, s, opposite[0], opposite[1]) { continue; }
                let inserted = [
                    Triangle { a: q, b: s, c: opposite[0] },
                    Triangle { a: q, b: s, c: opposite[1] },
                ];
                let replacement = triangulation_max(&p, &inserted);
                if angle_cmp(&p, replacement, worst) < 0 { worst = replacement; accepted = true; break; }
            }
            if accepted { break; }
        }
    }
    angle_rank(&p, n, worst)
}
