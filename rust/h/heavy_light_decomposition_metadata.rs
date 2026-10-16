const MAX_VERTICES: usize = 128;

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn heavy_light_decomposition_metadata(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let nv = values[0];
    let mv = values[1];
    if nv < 1 || nv > MAX_VERTICES as i64 || mv != nv - 1 || length != 2 + 2 * mv as usize {
        return -1;
    }
    let n = nv as usize;
    let m = mv as usize;
    let mut adjacency = [0i32; MAX_VERTICES * MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    for edge in 0..m {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv || u_value == v_value {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        for i in 0..degree[u] {
            if adjacency[u * MAX_VERTICES + i] == v as i32 {
                return -1;
            }
        }
        adjacency[u * MAX_VERTICES + degree[u]] = v as i32;
        degree[u] += 1;
        adjacency[v * MAX_VERTICES + degree[v]] = u as i32;
        degree[v] += 1;
    }

    let mut parent = [-2i32; MAX_VERTICES];
    let mut order = [0i32; MAX_VERTICES];
    let mut stack = [0i32; MAX_VERTICES];
    parent[0] = -1;
    let mut top = 1usize;
    let mut order_count = 0usize;
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let vertex = stack[top] as usize;
        order[order_count] = vertex as i32;
        order_count += 1;
        for i in (0..degree[vertex]).rev() {
            let child = adjacency[vertex * MAX_VERTICES + i] as usize;
            if parent[child] == -2 {
                parent[child] = vertex as i32;
                stack[top] = child as i32;
                top += 1;
            }
        }
    }
    if order_count != n {
        return -1;
    }

    let mut subtree_size = [0usize; MAX_VERTICES];
    let mut big_child = [-1i32; MAX_VERTICES];
    for index in (0..n).rev() {
        let vertex = order[index] as usize;
        let mut best_size = 0usize;
        subtree_size[vertex] = 1;
        for i in 0..degree[vertex] {
            let child = adjacency[vertex * MAX_VERTICES + i] as usize;
            if parent[child] != vertex as i32 {
                continue;
            }
            subtree_size[vertex] += subtree_size[child];
            if subtree_size[child] > best_size {
                best_size = subtree_size[child];
                big_child[vertex] = child as i32;
            }
        }
    }

    let mut position = [0usize; MAX_VERTICES];
    let mut head = [0i32; MAX_VERTICES];
    let mut stack_head = [0i32; MAX_VERTICES];
    top = 1;
    let mut next_position = 0usize;
    stack[0] = 0;
    stack_head[0] = 0;
    while top > 0 {
        top -= 1;
        let vertex = stack[top] as usize;
        let chain_head = stack_head[top];
        position[vertex] = next_position;
        next_position += 1;
        head[vertex] = chain_head;
        for i in (0..degree[vertex]).rev() {
            let child = adjacency[vertex * MAX_VERTICES + i] as usize;
            if parent[child] == vertex as i32 && child as i32 != big_child[vertex] {
                stack[top] = child as i32;
                stack_head[top] = child as i32;
                top += 1;
            }
        }
        if big_child[vertex] >= 0 {
            stack[top] = big_child[vertex];
            stack_head[top] = chain_head;
            top += 1;
        }
    }

    let required = (1 + 3 * n) * 8;
    if output.is_null() || capacity < required {
        return -2;
    }
    let out = std::slice::from_raw_parts_mut(output, required);
    put_i64(out, 0, nv);
    let mut cursor = 1usize;
    for vertex in 0..n {
        put_i64(out, cursor * 8, position[vertex] as i64);
        cursor += 1;
        put_i64(out, cursor * 8, head[vertex] as i64);
        cursor += 1;
        put_i64(out, cursor * 8, big_child[vertex] as i64);
        cursor += 1;
    }
    required as i64
}
