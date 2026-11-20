// Clean-room bounded rotation-system planarity recognizer.
const MAX_N: usize = 6;
const MAX_M: usize = 15;
const MAX_DARTS: usize = 30;

#[no_mangle]
pub unsafe extern "C" fn rotation_system_planarity_test(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 33 { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut edge_u = [0usize; MAX_M];
    let mut edge_v = [0usize; MAX_M];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }
    if n >= 3 && m > 3 * n - 6 { return 0; }
    let mut edge_id = [[-1i32; MAX_N]; MAX_N];
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for edge in 0..m {
        edge_id[edge_u[edge]][edge_v[edge]] = edge as i32;
        edge_id[edge_v[edge]][edge_u[edge]] = edge as i32;
    }
    for u in 0..n { for v in 0..n { if adjacent[u][v] { neighbors[u][degree[u]] = v; degree[u] += 1; } } }

    let mut component = [-1i32; MAX_N];
    let mut component_vertices = [[0usize; MAX_N]; MAX_N];
    let mut component_size = [0usize; MAX_N];
    let mut component_count = 0usize;
    for root in 0..n {
        if component[root] == -1 {
            let cid = component_count;
            component_count += 1;
            let mut queue = [0usize; MAX_N];
            let mut head = 0usize;
            let mut tail = 0usize;
            component[root] = cid as i32;
            queue[tail] = root;
            tail += 1;
            while head < tail {
                let here = queue[head];
                head += 1;
                component_vertices[cid][component_size[cid]] = here;
                component_size[cid] += 1;
                for there in 0..n {
                    if adjacent[here][there] && component[there] == -1 {
                        component[there] = cid as i32;
                        queue[tail] = there;
                        tail += 1;
                    }
                }
            }
        }
    }
    for cid in 0..component_count {
        let mut component_edges = 0usize;
        for edge in 0..m { if component[edge_u[edge]] == cid as i32 { component_edges += 1; } }
        if component_size[cid] >= 3 && component_edges > 3 * component_size[cid] - 6 { return 0; }
        if component_size[cid] == 1 { continue; }
        let mut rotation = [[0usize; MAX_N]; MAX_N];
        for i in 0..component_size[cid] {
            let vertex = component_vertices[cid][i];
            for j in 0..degree[vertex] { rotation[vertex][j] = neighbors[vertex][j]; }
        }
        let mut found = false;
        let mut done = false;
        while !found && !done {
            let mut successor = [-1i32; MAX_DARTS];
            for i in 0..component_size[cid] {
                let vertex = component_vertices[cid][i];
                let d = degree[vertex];
                for j in 0..d {
                    let next = (j + 1) % d;
                    let edge = edge_id[vertex][rotation[vertex][j]] as usize;
                    let next_edge = edge_id[vertex][rotation[vertex][next]] as usize;
                    let dart = 2 * edge + (if edge_u[edge] == vertex { 0 } else { 1 });
                    let next_dart = 2 * next_edge + (if edge_u[next_edge] == vertex { 0 } else { 1 });
                    successor[dart] = next_dart as i32;
                }
            }
            let mut used = [false; MAX_DARTS];
            let mut faces = 0i32;
            for edge in 0..m {
                if component[edge_u[edge]] == cid as i32 {
                    for orientation in 0..2 {
                        let mut dart = 2 * edge + orientation;
                        if !used[dart] {
                            faces += 1;
                            while !used[dart] {
                                used[dart] = true;
                                dart = successor[dart ^ 1] as usize;
                            }
                        }
                    }
                }
            }
            if component_size[cid] as i32 - component_edges as i32 + faces == 2 {
                found = true;
            } else {
                let mut position = component_size[cid] as i32 - 1;
                let mut advanced = false;
                while position >= 0 && !advanced {
                    let vertex = component_vertices[cid][position as usize];
                    let d = degree[vertex];
                    let mut pivot = d as i32 - 2;
                    while pivot >= 1 && rotation[vertex][pivot as usize] >= rotation[vertex][pivot as usize + 1] { pivot -= 1; }
                    if pivot >= 1 {
                        let mut swap_at = d - 1;
                        while rotation[vertex][swap_at] <= rotation[vertex][pivot as usize] { swap_at -= 1; }
                        rotation[vertex].swap(pivot as usize, swap_at);
                        let mut left = pivot as usize + 1;
                        let mut right = d - 1;
                        while left < right { rotation[vertex].swap(left, right); left += 1; right -= 1; }
                        advanced = true;
                    } else {
                        for j in 0..d { rotation[vertex][j] = neighbors[vertex][j]; }
                        position -= 1;
                    }
                }
                if !advanced { done = true; }
            }
        }
        if !found { return 0; }
    }
    1
}
