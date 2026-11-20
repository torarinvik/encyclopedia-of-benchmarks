const VERTICES: usize = 8;
const EDGES: usize = 28;
const TRIANGLES: usize = 56;
const INPUT_WORDS: usize = 59;
const OUTPUT_WORDS: usize = 170;

#[derive(Clone, Copy, Default)]
struct Triangle {
    a: usize,
    b: usize,
    c: usize,
    e0: usize,
    e1: usize,
    e2: usize,
    active: bool,
}

fn select_triangle(
    chosen: usize,
    triangles: &mut [Triangle; TRIANGLES],
    triangle_count: usize,
    incidence: &mut [i32; EDGES],
    used: &mut [i32; EDGES],
    staged: &mut [i64; OUTPUT_WORDS],
    face_count: &mut usize,
) {
    let triangle = triangles[chosen];
    triangles[chosen].active = false;
    staged[2 + 3 * *face_count] = triangle.a as i64;
    staged[3 + 3 * *face_count] = triangle.b as i64;
    staged[4 + 3 * *face_count] = triangle.c as i64;
    *face_count += 1;

    let edges = [triangle.e0, triangle.e1, triangle.e2];
    let mut saturated = [false; EDGES];
    for edge in edges {
        incidence[edge] -= 1;
        used[edge] += 1;
        if used[edge] == 2 { saturated[edge] = true; }
    }
    for other in 0..triangle_count {
        if !triangles[other].active { continue; }
        let t = triangles[other];
        if saturated[t.e0] || saturated[t.e1] || saturated[t.e2] {
            triangles[other].active = false;
            incidence[t.e0] -= 1;
            incidence[t.e1] -= 1;
            incidence[t.e2] -= 1;
        }
    }
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    for byte in 0..8 { output[offset + byte] = ((value as u64) >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn triangle_mesh_faces_from_edge_graph(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length < 2 || length > INPUT_WORDS { return -1; }
    let input = unsafe { std::slice::from_raw_parts(raw, length) };
    let vertex_word = input[0];
    let edge_word = input[1];
    if !(3..=VERTICES as i64).contains(&vertex_word) || edge_word < 0 || edge_word > EDGES as i64 { return -1; }
    let vertices = vertex_word as usize;
    let edge_count = edge_word as usize;
    if edge_count > vertices * (vertices - 1) / 2 || length != 2 + 2 * edge_count { return -1; }

    let mut edge_index = [[-1_i32; VERTICES]; VERTICES];
    let mut vertex_degree = [0_i32; VERTICES];
    for edge in 0..edge_count {
        let left_word = input[2 + 2 * edge];
        let right_word = input[3 + 2 * edge];
        if left_word < 0 || left_word >= vertex_word || right_word < 0 || right_word >= vertex_word || left_word == right_word { return -1; }
        let mut left = left_word as usize;
        let mut right = right_word as usize;
        if left > right { std::mem::swap(&mut left, &mut right); }
        if edge_index[left][right] >= 0 { return -1; }
        edge_index[left][right] = edge as i32;
        edge_index[right][left] = edge as i32;
        vertex_degree[left] += 1;
        vertex_degree[right] += 1;
    }

    let mut triangles = [Triangle::default(); TRIANGLES];
    let mut triangle_count = 0_usize;
    let mut incidence = [0_i32; EDGES];
    for a in 0..vertices {
        for b in (a + 1)..vertices {
            for c in (b + 1)..vertices {
                let e0 = edge_index[a][b];
                let e1 = edge_index[a][c];
                let e2 = edge_index[b][c];
                if e0 >= 0 && e1 >= 0 && e2 >= 0 {
                    let ids = [e0 as usize, e1 as usize, e2 as usize];
                    triangles[triangle_count] = Triangle { a, b, c, e0: ids[0], e1: ids[1], e2: ids[2], active: true };
                    triangle_count += 1;
                    for id in ids { incidence[id] += 1; }
                }
            }
        }
    }

    let mut used = [0_i32; EDGES];
    let mut staged = [0_i64; OUTPUT_WORDS];
    let mut face_count = 0_usize;
    let mut fallback_used = false;
    loop {
        let mut chosen = triangle_count;
        for index in 0..triangle_count {
            let t = triangles[index];
            if t.active && (vertex_degree[t.a] == 3 || vertex_degree[t.b] == 3 || vertex_degree[t.c] == 3) { chosen = index; break; }
        }
        if chosen < triangle_count {
            select_triangle(chosen, &mut triangles, triangle_count, &mut incidence, &mut used, &mut staged, &mut face_count);
            continue;
        }

        let mut forced = [false; EDGES];
        for edge in 0..edge_count { forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge]; }
        chosen = triangle_count;
        for index in 0..triangle_count {
            let t = triangles[index];
            if t.active && (forced[t.e0] || forced[t.e1] || forced[t.e2]) { chosen = index; break; }
        }
        if chosen < triangle_count {
            select_triangle(chosen, &mut triangles, triangle_count, &mut incidence, &mut used, &mut staged, &mut face_count);
            continue;
        }

        let mut best_score = 3 * TRIANGLES as i32 + 1;
        chosen = triangle_count;
        for index in 0..triangle_count {
            let t = triangles[index];
            if !t.active { continue; }
            let score = incidence[t.e0] + incidence[t.e1] + incidence[t.e2];
            if score < best_score { chosen = index; best_score = score; }
        }
        if chosen == triangle_count { break; }
        fallback_used = true;
        select_triangle(chosen, &mut triangles, triangle_count, &mut incidence, &mut used, &mut staged, &mut face_count);
    }

    let mut complete = edge_count > 0;
    for edge in 0..edge_count { if used[edge] != 2 { complete = false; } }
    staged[0] = (if complete { 0 } else { 2 }) + (if fallback_used { 1 } else { 0 });
    staged[1] = face_count as i64;
    let output_bytes = (2 + 3 * face_count) * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for word in 0..(2 + 3 * face_count) { store_i64_le(destination, word * 8, staged[word]); }
    output_bytes as i64
}
