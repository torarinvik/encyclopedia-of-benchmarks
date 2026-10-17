const MAX_VERTICES: usize = 14;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 17;

fn find_root(parent: &mut [usize; MAX_VERTICES], mut vertex: usize) -> usize {
    while parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    vertex
}

#[no_mangle]
pub unsafe extern "C" fn mcoloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) { return -1; }
    let n_value = *input;
    let colors_value = *input.add(1);
    if !(0..=MAX_VERTICES as i64).contains(&n_value) || !(1..=MAX_VERTICES as i64).contains(&colors_value) { return -1; }
    let n = n_value as usize;
    if length != n + 2 { return -1; }

    let mut masks = [0_u32; MAX_VERTICES];
    let valid_mask = if n == 0 { 0 } else { (1_u32 << n) - 1 };
    let mut parent = [0_usize; MAX_VERTICES];
    for vertex in 0..n {
        let raw = *input.add(vertex + 2);
        if raw < 0 || raw as u64 > valid_mask as u64 { return -1; }
        masks[vertex] = raw as u32;
        if masks[vertex] & (1_u32 << vertex) != 0 { return -1; }
        parent[vertex] = vertex;
    }
    for vertex in 0..n {
        for neighbor in vertex + 1..n {
            let edge = masks[vertex] & (1_u32 << neighbor) != 0;
            if edge != (masks[neighbor] & (1_u32 << vertex) != 0) { return -1; }
            if edge {
                let root_a = find_root(&mut parent, vertex);
                let root_b = find_root(&mut parent, neighbor);
                if root_a == root_b { return -1; }
                parent[root_a] = root_b;
            }
        }
    }

    let mut colors = [1_i32; MAX_VERTICES];
    let mut visited = [false; MAX_VERTICES];
    let mut queue = [0_usize; MAX_VERTICES];
    let mut maximum_color = 1_i32;
    for start in 0..n {
        if visited[start] { continue; }
        let mut head = 0;
        let mut tail = 0;
        visited[start] = true;
        queue[tail] = start;
        tail += 1;
        while head < tail {
            let vertex = queue[head];
            head += 1;
            for neighbor in 0..n {
                if masks[vertex] & (1_u32 << neighbor) == 0 { continue; }
                if colors[vertex] == colors[neighbor] { colors[neighbor] += 1; }
                maximum_color = maximum_color.max(colors[vertex]).max(colors[neighbor]);
                if maximum_color > colors_value as i32 { return 0; }
                if !visited[neighbor] {
                    visited[neighbor] = true;
                    queue[tail] = neighbor;
                    tail += 1;
                }
            }
        }
    }
    1
}
