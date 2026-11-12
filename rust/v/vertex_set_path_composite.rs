const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MODULUS: i64 = 998_244_353;
const MAX_INPUT_VALUES: usize = 4 * MAX_N + 4 * MAX_Q;

#[derive(Clone, Copy)]
struct Affine {
    a: i64,
    b: i64,
}

#[derive(Clone, Copy)]
struct Aggregate {
    forward: Affine,
    backward: Affine,
}

fn identity() -> Affine {
    Affine { a: 1, b: 0 }
}

fn compose(after: Affine, before: Affine) -> Affine {
    Affine {
        a: (after.a * before.a) % MODULUS,
        b: (after.a * before.b + after.b) % MODULUS,
    }
}

fn identity_aggregate() -> Aggregate {
    let id = identity();
    Aggregate { forward: id, backward: id }
}

fn combine(left: Aggregate, right: Aggregate) -> Aggregate {
    Aggregate {
        forward: compose(right.forward, left.forward),
        backward: compose(left.backward, right.backward),
    }
}

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn update_leaf(tree: &mut [Aggregate; 2 * MAX_N], base: usize, position: usize, value: Affine) {
    let mut node = base + position;
    tree[node] = Aggregate { forward: value, backward: value };
    while node > 1 {
        node >>= 1;
        tree[node] = combine(tree[node << 1], tree[(node << 1) | 1]);
    }
}

fn range_query(tree: &[Aggregate; 2 * MAX_N], base: usize, left: usize, right: usize) -> Aggregate {
    let mut prefix = identity_aggregate();
    let mut suffix = identity_aggregate();
    let mut left = left + base;
    let mut right = right + base;
    while left < right {
        if left & 1 != 0 {
            prefix = combine(prefix, tree[left]);
            left += 1;
        }
        if right & 1 != 0 {
            right -= 1;
            suffix = combine(tree[right], suffix);
        }
        left >>= 1;
        right >>= 1;
    }
    combine(prefix, suffix)
}

fn path_composition(
    tree: &[Aggregate; 2 * MAX_N],
    base: usize,
    parent: &[usize; MAX_N],
    depth: &[usize; MAX_N],
    head: &[usize; MAX_N],
    position: &[usize; MAX_N],
    mut from: usize,
    mut to: usize,
) -> Affine {
    let mut left = identity();
    let mut right = identity();
    while head[from] != head[to] {
        if depth[head[from]] >= depth[head[to]] {
            let part = range_query(tree, base, position[head[from]], position[from] + 1);
            left = compose(part.backward, left);
            from = parent[head[from]];
        } else {
            let part = range_query(tree, base, position[head[to]], position[to] + 1);
            right = compose(right, part.forward);
            to = parent[head[to]];
        }
    }
    if depth[from] >= depth[to] {
        let part = range_query(tree, base, position[to], position[from] + 1);
        left = compose(part.backward, left);
    } else {
        let part = range_query(tree, base, position[from], position[to] + 1);
        right = compose(right, part.forward);
    }
    compose(right, left)
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vertex_set_path_composite(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 8 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 4 * n + 4 * q {
        return -1;
    }

    let mut values = [Affine { a: 1, b: 0 }; MAX_N];
    for vertex in 0..n {
        let a = *input.add(2 + 2 * vertex);
        let b = *input.add(3 + 2 * vertex);
        if a < 1 || a >= MODULUS || b < 0 || b >= MODULUS {
            return -1;
        }
        values[vertex] = Affine { a, b };
    }

    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut dsu_parent = [0usize; MAX_N];
    let mut dsu_size = [0usize; MAX_N];
    for vertex in 0..n {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    let edge_start = 2 + 2 * n;
    for edge in 0..(n - 1) {
        let offset = edge_start + 2 * edge;
        let left_value = *input.add(offset);
        let right_value = *input.add(offset + 1);
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value {
            return -1;
        }
        let left = left_value as usize;
        let right = right_value as usize;
        let mut root_left = find_root(&mut dsu_parent, left);
        let mut root_right = find_root(&mut dsu_parent, right);
        if root_left == root_right {
            return -1;
        }
        if dsu_size[root_left] < dsu_size[root_right] {
            std::mem::swap(&mut root_left, &mut root_right);
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    let operation_start = edge_start + 2 * (n - 1);
    for query in 0..q {
        let offset = operation_start + 4 * query;
        let kind = *input.add(offset);
        let first = *input.add(offset + 1);
        let second = *input.add(offset + 2);
        let third = *input.add(offset + 3);
        if kind == 0 {
            if first < 0 || first >= n_value || second < 1 || second >= MODULUS ||
                third < 0 || third >= MODULUS {
                return -1;
            }
        } else if kind == 1 {
            if first < 0 || first >= n_value || second < 0 || second >= n_value ||
                third < 0 || third >= MODULUS {
                return -1;
            }
        } else {
            return -1;
        }
    }

    let mut parent = [0usize; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut subtree = [0usize; MAX_N];
    let mut heavy = [MAX_N; MAX_N];
    let mut order = [0usize; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut order_count = 0usize;
    let mut top = 1usize;
    parent[0] = 0;
    subtree[0] = 1;
    stack[0] = 0;
    order[order_count] = 0;
    order_count += 1;
    while top > 0 {
        top -= 1;
        let vertex = stack[top];
        for neighbor in 0..n {
            if !adjacent[vertex][neighbor] || neighbor == parent[vertex] {
                continue;
            }
            parent[neighbor] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            subtree[neighbor] = 1;
            order[order_count] = neighbor;
            order_count += 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    for index in (1..order_count).rev() {
        let vertex = order[index];
        let p = parent[vertex];
        subtree[p] += subtree[vertex];
        if heavy[p] == MAX_N || subtree[vertex] > subtree[heavy[p]] ||
            (subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p]) {
            heavy[p] = vertex;
        }
    }

    let mut head = [0usize; MAX_N];
    let mut position = [0usize; MAX_N];
    let mut chain_vertex = [0usize; MAX_N];
    let mut chain_head = [0usize; MAX_N];
    let mut chain_count = 1usize;
    let mut timer = 0usize;
    chain_vertex[0] = 0;
    chain_head[0] = 0;
    while chain_count > 0 {
        chain_count -= 1;
        let mut vertex = chain_vertex[chain_count];
        let current_head = chain_head[chain_count];
        while vertex != MAX_N {
            head[vertex] = current_head;
            position[vertex] = timer;
            timer += 1;
            for child in 0..n {
                if adjacent[vertex][child] && parent[child] == vertex && child != heavy[vertex] {
                    chain_vertex[chain_count] = child;
                    chain_head[chain_count] = child;
                    chain_count += 1;
                }
            }
            vertex = heavy[vertex];
        }
    }

    let mut base = 1usize;
    while base < n {
        base <<= 1;
    }
    let mut tree = [identity_aggregate(); 2 * MAX_N];
    for vertex in 0..n {
        update_leaf(&mut tree, base, position[vertex], values[vertex]);
    }

    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    for query in 0..q {
        let offset = operation_start + 4 * query;
        let kind = *input.add(offset);
        let first = *input.add(offset + 1) as usize;
        let second = *input.add(offset + 2);
        let third = *input.add(offset + 3);
        if kind == 0 {
            values[first] = Affine { a: second, b: third };
            update_leaf(&mut tree, base, position[first], values[first]);
        } else {
            let combined = path_composition(&tree, base, &parent, &depth, &head, &position,
                first, second as usize);
            answers[answer_count] = (combined.a * third + combined.b) % MODULUS;
            answer_count += 1;
        }
    }

    let required = 8 * answer_count;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..answer_count {
        store_i64_le(output, 8 * index, answers[index]);
    }
    required as i64
}
