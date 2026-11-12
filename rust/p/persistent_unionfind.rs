const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT_VALUES: usize = 2 + 4 * MAX_Q;

fn find_root(parent: &[usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        item = parent[item];
    }
    item
}

fn visit_version(
    node: usize,
    kind: &[i64; MAX_Q],
    u: &[i64; MAX_Q],
    v: &[i64; MAX_Q],
    first_child: &[i64; MAX_Q + 1],
    next_sibling: &[i64; MAX_Q],
    parent: &mut [usize; MAX_N],
    set_size: &mut [usize; MAX_N],
    answer: &mut [i64; MAX_Q + 1],
    history_child: &mut [i64; MAX_Q],
    history_root: &mut [i64; MAX_Q],
    history_size: &mut [i64; MAX_Q],
    history_count: &mut usize,
) {
    let saved_history = *history_count;
    if node != 0 {
        let operation = node - 1;
        if kind[operation] == 0 {
            let mut root_u = find_root(parent, u[operation] as usize);
            let mut root_v = find_root(parent, v[operation] as usize);
            if root_u == root_v {
                history_child[*history_count] = -1;
                history_root[*history_count] = -1;
                history_size[*history_count] = 0;
            } else {
                if set_size[root_u] > set_size[root_v] {
                    std::mem::swap(&mut root_u, &mut root_v);
                }
                history_child[*history_count] = root_u as i64;
                history_root[*history_count] = root_v as i64;
                history_size[*history_count] = set_size[root_v] as i64;
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
            }
            *history_count += 1;
        } else {
            answer[node] = if find_root(parent, u[operation] as usize)
                == find_root(parent, v[operation] as usize) { 1 } else { 0 };
        }
    }
    let mut child = first_child[node];
    while child >= 0 {
        visit_version(
            child as usize,
            kind,
            u,
            v,
            first_child,
            next_sibling,
            parent,
            set_size,
            answer,
            history_child,
            history_root,
            history_size,
            history_count,
        );
        child = next_sibling[child as usize - 1];
    }
    while *history_count > saved_history {
        *history_count -= 1;
        let child = history_child[*history_count];
        if child >= 0 {
            let root = history_root[*history_count] as usize;
            parent[child as usize] = child as usize;
            set_size[root] = history_size[*history_count] as usize;
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn persistent_unionfind(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + 4 * q {
        return -1;
    }

    let mut kind = [0i64; MAX_Q];
    let mut u = [0i64; MAX_Q];
    let mut v = [0i64; MAX_Q];
    let mut first_child = [-1i64; MAX_Q + 1];
    let mut next_sibling = [0i64; MAX_Q];
    let mut answer = [0i64; MAX_Q + 1];
    let mut query_count = 0usize;
    for operation in 0..q {
        let offset = 2 + 4 * operation;
        kind[operation] = *input.add(offset);
        let version = *input.add(offset + 1);
        u[operation] = *input.add(offset + 2);
        v[operation] = *input.add(offset + 3);
        if (kind[operation] != 0 && kind[operation] != 1)
            || version < -1
            || version >= operation as i64
            || u[operation] < 0
            || u[operation] >= n_value
            || v[operation] < 0
            || v[operation] >= n_value
        {
            return -1;
        }
        if version >= 0 && kind[version as usize] != 0 {
            return -1;
        }
        if kind[operation] == 1 {
            query_count += 1;
        }
        let parent_node = (version + 1) as usize;
        next_sibling[operation] = first_child[parent_node];
        first_child[parent_node] = (operation + 1) as i64;
    }

    let required = 8 * query_count;
    if output.is_null() || capacity < required {
        return -2;
    }
    let mut parent = [0usize; MAX_N];
    let mut set_size = [0usize; MAX_N];
    for item in 0..n {
        parent[item] = item;
        set_size[item] = 1;
    }
    let mut history_child = [0i64; MAX_Q];
    let mut history_root = [0i64; MAX_Q];
    let mut history_size = [0i64; MAX_Q];
    let mut history_count = 0usize;
    visit_version(
        0,
        &kind,
        &u,
        &v,
        &first_child,
        &next_sibling,
        &mut parent,
        &mut set_size,
        &mut answer,
        &mut history_child,
        &mut history_root,
        &mut history_size,
        &mut history_count,
    );
    let mut written = 0usize;
    for operation in 0..q {
        if kind[operation] == 1 {
            store_i64_le(output, written, answer[operation + 1]);
            written += 8;
        }
    }
    written as i64
}
