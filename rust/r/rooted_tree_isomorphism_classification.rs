const MAX_TREES: usize = 16;
const MAX_TREE_VERTICES: usize = 32;
const MAX_TOTAL_VERTICES: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES;

#[derive(Clone, Copy)]
struct Signature {
    child_count: usize,
    child_types: [usize; MAX_TREE_VERTICES],
}

impl Signature {
    const EMPTY: Self = Self {
        child_count: 0,
        child_types: [0; MAX_TREE_VERTICES],
    };
}

fn intern_signature(
    signatures: &mut [Signature; MAX_TOTAL_VERTICES],
    signature_count: &mut usize,
    children: &[usize; MAX_TREE_VERTICES],
    child_count: usize,
) -> Option<usize> {
    for signature in 0..*signature_count {
        if signatures[signature].child_count != child_count {
            continue;
        }
        if signatures[signature].child_types[..child_count] == children[..child_count] {
            return Some(signature);
        }
    }
    if *signature_count >= MAX_TOTAL_VERTICES {
        return None;
    }
    let result = *signature_count;
    signatures[result].child_count = child_count;
    signatures[result].child_types[..child_count].copy_from_slice(&children[..child_count]);
    *signature_count += 1;
    Some(result)
}

fn canonical_root_type(
    adjacency: &[u32; MAX_TREE_VERTICES],
    n: usize,
    root: usize,
    signatures: &mut [Signature; MAX_TOTAL_VERTICES],
    signature_count: &mut usize,
) -> Option<usize> {
    let mut parent = [MAX_TREE_VERTICES; MAX_TREE_VERTICES];
    let mut order = [0; MAX_TREE_VERTICES];
    let mut stack = [0; MAX_TREE_VERTICES];
    let mut node_type = [0; MAX_TREE_VERTICES];
    let mut visited = [false; MAX_TREE_VERTICES];
    parent[root] = root;
    visited[root] = true;
    let (mut stack_size, mut order_size) = (1, 0);
    stack[0] = root;
    while stack_size != 0 {
        stack_size -= 1;
        let vertex = stack[stack_size];
        order[order_size] = vertex;
        order_size += 1;
        for neighbor in 0..n {
            let bit = 1_u32 << neighbor;
            if adjacency[vertex] & bit == 0 || neighbor == parent[vertex] {
                continue;
            }
            if visited[neighbor] {
                return None;
            }
            visited[neighbor] = true;
            parent[neighbor] = vertex;
            stack[stack_size] = neighbor;
            stack_size += 1;
        }
    }
    if order_size != n {
        return None;
    }

    for reverse in (0..order_size).rev() {
        let vertex = order[reverse];
        let mut children = [0; MAX_TREE_VERTICES];
        let mut child_count = 0;
        for candidate in 0..n {
            if candidate != vertex && parent[candidate] == vertex {
                children[child_count] = node_type[candidate];
                child_count += 1;
            }
        }
        children[..child_count].sort_unstable();
        node_type[vertex] = intern_signature(signatures, signature_count, &children, child_count)?;
    }
    Some(node_type[root])
}

#[no_mangle]
pub unsafe extern "C" fn rooted_tree_isomorphism_classification(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_TREES as i64 {
        return -1;
    }
    let tree_count = values[0] as usize;
    let mut signatures = [Signature::EMPTY; MAX_TOTAL_VERTICES];
    let mut signature_count = 0;
    let mut root_types = [0; MAX_TREES];
    let mut labels = [0_u8; MAX_TREES];
    let (mut position, mut total_vertices, mut class_count) = (1, 0, 0);

    for tree in 0..tree_count {
        if position + 2 > length {
            return -1;
        }
        let (n_value, root_value) = (values[position], values[position + 1]);
        position += 2;
        if n_value < 1 || n_value > MAX_TREE_VERTICES as i64 || root_value < 0 || root_value >= n_value {
            return -1;
        }
        let n = n_value as usize;
        total_vertices += n;
        if total_vertices > MAX_TOTAL_VERTICES {
            return -1;
        }
        let edge_count = n - 1;
        if 2 * edge_count > length - position {
            return -1;
        }
        let mut adjacency = [0_u32; MAX_TREE_VERTICES];
        for _ in 0..edge_count {
            let (left_value, right_value) = (values[position], values[position + 1]);
            position += 2;
            if left_value < 0 || right_value < 0 || left_value >= n_value ||
                right_value >= n_value || left_value == right_value {
                return -1;
            }
            let (left, right) = (left_value as usize, right_value as usize);
            let (left_bit, right_bit) = (1_u32 << left, 1_u32 << right);
            if adjacency[left] & right_bit != 0 {
                return -1;
            }
            adjacency[left] |= right_bit;
            adjacency[right] |= left_bit;
        }
        let Some(root_type) = canonical_root_type(
            &adjacency,
            n,
            root_value as usize,
            &mut signatures,
            &mut signature_count,
        ) else {
            return -1;
        };
        root_types[tree] = root_type;
        if let Some(prior) = (0..tree).find(|&prior| root_types[prior] == root_type) {
            labels[tree] = labels[prior];
        } else {
            labels[tree] = class_count as u8;
            class_count += 1;
        }
    }
    if position != length {
        return -1;
    }
    if output.is_null() || output_capacity < tree_count {
        return -2;
    }
    for tree in 0..tree_count {
        unsafe { *output.add(tree) = labels[tree] };
    }
    tree_count as i64
}
