const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const MODULUS: i64 = 998_244_353;
type Matrix = [i64; 4];

fn normalize(value: i64) -> i64 { value.rem_euclid(MODULUS) }

fn multiply(left: Matrix, right: Matrix) -> Matrix {
    let mut result = [0_i64; 4];
    for row in 0..2 {
        for column in 0..2 {
            for inner in 0..2 {
                result[2 * row + column] = normalize(result[2 * row + column] +
                    left[2 * row + inner] * right[2 * inner + column]);
            }
        }
    }
    result
}

fn inverse(matrix: Matrix) -> Matrix {
    [matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0]]
}

fn find_root(parent: &mut [usize; MAX_N], difference: &mut [Matrix; MAX_N], item: usize) -> usize {
    if parent[item] != item {
        let old_parent = parent[item];
        let root = find_root(parent, difference, old_parent);
        difference[item] = multiply(difference[old_parent], difference[item]);
        parent[item] = root;
    }
    parent[item]
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn unionfind_with_potential_non_commutative_group(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 9 || length > 2 + 7 * MAX_Q { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + 7 * q { return -1; }
    for operation in 0..q {
        let position = 2 + 7 * operation;
        let kind = *input.add(position);
        let u = *input.add(position + 1);
        let v = *input.add(position + 2);
        if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1; }
        if kind == 0 {
            let matrix = [*input.add(position + 3), *input.add(position + 4),
                          *input.add(position + 5), *input.add(position + 6)];
            if matrix.iter().any(|&entry| entry < 0 || entry >= MODULUS) ||
                normalize(matrix[0] * matrix[3] - matrix[1] * matrix[2]) != 1 { return -1; }
        } else if kind == 1 {
            for cell in 0..4 { if *input.add(position + 3 + cell) != 0 { return -1; } }
        } else { return -1; }
    }
    let required = 32 * q;
    if output.is_null() || capacity < required { return -2; }

    let mut parent = [0usize; MAX_N];
    let mut set_size = [0usize; MAX_N];
    let mut difference = [[1, 0, 0, 1]; MAX_N];
    for item in 0..n { parent[item] = item; set_size[item] = 1; }
    for operation in 0..q {
        let position = 2 + 7 * operation;
        let kind = *input.add(position);
        let u = *input.add(position + 1) as usize;
        let v = *input.add(position + 2) as usize;
        let mut row = [0_i64; 4];
        let root_u = find_root(&mut parent, &mut difference, u);
        let root_v = find_root(&mut parent, &mut difference, v);
        if kind == 1 {
            if root_u == root_v { row = multiply(inverse(difference[v]), difference[u]); }
            else { row = [-1; 4]; }
        } else {
            let relation = [*input.add(position + 3), *input.add(position + 4),
                            *input.add(position + 5), *input.add(position + 6)];
            if root_u == root_v {
                row[0] = i64::from(multiply(inverse(difference[v]), difference[u]) == relation);
            } else if set_size[root_u] < set_size[root_v] {
                difference[root_u] = multiply(multiply(difference[v], relation), inverse(difference[u]));
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
                row[0] = 1;
            } else {
                difference[root_v] = multiply(multiply(difference[u], inverse(relation)), inverse(difference[v]));
                parent[root_v] = root_u;
                set_size[root_u] += set_size[root_v];
                row[0] = 1;
            }
        }
        for cell in 0..4 { store_i64_le(output, 32 * operation + 8 * cell, row[cell]); }
    }
    required as i64
}
