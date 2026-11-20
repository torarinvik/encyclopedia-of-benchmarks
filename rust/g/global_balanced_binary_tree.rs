const MAX_N: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 65;

fn build_interval(
    lo: usize,
    hi: usize,
    path: &[usize; MAX_N],
    prefix: &[usize; MAX_N + 1],
    gbst_parent: &mut [i64; MAX_N],
    left_child: &mut [i64; MAX_N],
    right_child: &mut [i64; MAX_N],
    local_size: &mut [i64; MAX_N],
) -> usize {
    let total_weight = prefix[hi] - prefix[lo];
    let mut low = lo;
    let mut high = hi;
    while high - low > 1 {
        let middle = (low + high) / 2;
        if 2 * (prefix[middle] - prefix[lo]) <= total_weight {
            low = middle;
        } else {
            high = middle;
        }
    }

    let pivot = low;
    let node = path[pivot];
    local_size[node] = (hi - lo) as i64;
    if lo < pivot {
        let child = build_interval(
            lo, pivot, path, prefix, gbst_parent, left_child, right_child, local_size,
        );
        left_child[node] = child as i64;
        gbst_parent[child] = node as i64;
    }
    if pivot + 1 < hi {
        let child = build_interval(
            pivot + 1, hi, path, prefix, gbst_parent, left_child, right_child, local_size,
        );
        right_child[node] = child as i64;
        gbst_parent[child] = node as i64;
    }
    node
}

#[no_mangle]
pub unsafe extern "C" fn global_balanced_binary_tree(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 {
        return -1;
    }
    if length != n_value as usize {
        return -1;
    }
    let n = n_value as usize;

    let mut parent = [-1i64; MAX_N];
    let mut subtree_size = [1usize; MAX_N];
    let mut heavy_child = [-1i64; MAX_N];
    let mut gbst_parent = [-1i64; MAX_N];
    let mut left_child = [-1i64; MAX_N];
    let mut right_child = [-1i64; MAX_N];
    let mut local_size = [0i64; MAX_N];
    let mut path = [0usize; MAX_N];
    let mut prefix = [0usize; MAX_N + 1];

    for vertex in 1..n {
        let p = values[vertex];
        if p < 0 || p >= vertex as i64 {
            return -1;
        }
        parent[vertex] = p;
    }
    for vertex in (1..n).rev() {
        subtree_size[parent[vertex] as usize] += subtree_size[vertex];
    }
    for vertex in 1..n {
        let p = parent[vertex] as usize;
        let current = heavy_child[p];
        if current < 0 || subtree_size[vertex] > subtree_size[current as usize] {
            heavy_child[p] = vertex as i64;
        }
    }

    for head in 0..n {
        if head > 0 && heavy_child[parent[head] as usize] == head as i64 {
            continue;
        }
        let mut path_length = 0usize;
        let mut vertex = head as i64;
        prefix[0] = 0;
        while vertex >= 0 {
            let node = vertex as usize;
            let child = heavy_child[node];
            let weight = subtree_size[node]
                - if child >= 0 { subtree_size[child as usize] } else { 0 };
            path[path_length] = node;
            prefix[path_length + 1] = prefix[path_length] + weight;
            path_length += 1;
            vertex = child;
        }
        let root = build_interval(
            0,
            path_length,
            &path,
            &prefix,
            &mut gbst_parent,
            &mut left_child,
            &mut right_child,
            &mut local_size,
        );
        gbst_parent[root] = if head == 0 { -1 } else { parent[head] };
    }

    let mut checksum = 0i64;
    for vertex in 0..n {
        let record = (gbst_parent[vertex] + 1)
            + 65 * (left_child[vertex] + 1)
            + 4225 * (right_child[vertex] + 1)
            + 274625 * local_size[vertex];
        checksum += (vertex as i64 + 1) * record;
    }
    checksum
}
