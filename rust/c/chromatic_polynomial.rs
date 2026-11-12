const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

type Adjacency = [u64; MAX_VERTICES];
type Polynomial = [i64; MAX_VERTICES + 1];

fn chromatic_poly(adjacency: Adjacency, n: usize) -> Polynomial {
    let mut edge = None;
    for u in 0..n {
        for v in u + 1..n {
            if adjacency[u] & (1u64 << v) != 0 {
                edge = Some((u, v));
                break;
            }
        }
        if edge.is_some() {
            break;
        }
    }
    let mut result = [0i64; MAX_VERTICES + 1];
    let Some((edge_u, edge_v)) = edge else {
        result[n] = 1;
        return result;
    };

    let mut deleted = adjacency;
    deleted[edge_u] &= !(1u64 << edge_v);
    deleted[edge_v] &= !(1u64 << edge_u);
    let without_edge = chromatic_poly(deleted, n);

    let mut contracted = [0u64; MAX_VERTICES];
    for left in 0..n {
        for right in left + 1..n {
            if adjacency[left] & (1u64 << right) == 0 || (left == edge_u && right == edge_v) {
                continue;
            }
            let remap = |vertex: usize| {
                let merged = if vertex == edge_v { edge_u } else { vertex };
                if merged > edge_v { merged - 1 } else { merged }
            };
            let new_left = remap(left);
            let new_right = remap(right);
            if new_left != new_right {
                contracted[new_left] |= 1u64 << new_right;
                contracted[new_right] |= 1u64 << new_left;
            }
        }
    }
    let with_edge_contracted = chromatic_poly(contracted, n - 1);
    for degree in 0..=n {
        result[degree] = without_edge[degree] - with_edge_contracted[degree];
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn chromatic_polynomial(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(0..=MAX_VERTICES as i64).contains(&n_value)
        || !(0..=MAX_EDGES as i64).contains(&m_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m {
        return -1;
    }

    let mut adjacency = [0u64; MAX_VERTICES];
    for edge in 0..m {
        let u_value = *input.add(2 + 2 * edge);
        let v_value = *input.add(3 + 2 * edge);
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        if adjacency[u] & (1u64 << v) != 0 {
            return -1;
        }
        adjacency[u] |= 1u64 << v;
        adjacency[v] |= 1u64 << u;
    }

    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let coefficients = chromatic_poly(adjacency, n);
    for degree in 0..=n {
        store_i64_le(output, 8 * degree, coefficients[degree]);
    }
    output_bytes as i64
}
