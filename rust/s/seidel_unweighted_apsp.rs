type Matrix = [[i64; 8]; 8];

fn distances(adjacency: &Matrix, n: usize) -> Matrix {
    let mut squared = [[0; 8]; 8];
    let mut expanded = [[0; 8]; 8];
    let mut degree = [0; 8];
    let mut complete = true;
    for i in 0..n {
        for j in 0..n {
            degree[i] += adjacency[i][j];
            if i != j && adjacency[i][j] == 0 { complete = false; }
            for k in 0..n { squared[i][j] += adjacency[i][k] * adjacency[k][j]; }
        }
    }
    let mut result = [[0; 8]; 8];
    if complete {
        for i in 0..n { for j in 0..n { result[i][j] = i64::from(i != j); } }
        return result;
    }
    for i in 0..n {
        for j in 0..n {
            expanded[i][j] = i64::from(i != j && (adjacency[i][j] != 0 || squared[i][j] != 0));
        }
    }
    let coarse = distances(&expanded, n);
    for i in 0..n {
        for j in 0..n {
            if i == j { continue; }
            let mut neighbor_sum = 0;
            for k in 0..n { neighbor_sum += coarse[i][k] * adjacency[k][j]; }
            result[i][j] = 2 * coarse[i][j] - i64::from(neighbor_sum < coarse[i][j] * degree[j]);
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn seidel_unweighted_apsp(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + n * n { return -1; }
    let mut adjacency = [[0; 8]; 8];
    for i in 0..n {
        for j in 0..n {
            let value = values[1 + i * n + j];
            if !(0..=1).contains(&value) || (i == j && value != 0) { return -1; }
            adjacency[i][j] = value;
        }
    }
    for i in 0..n { for j in 0..i { if adjacency[i][j] != adjacency[j][i] { return -1; } } }
    let mut seen = [false; 8];
    let mut queue = [0usize; 8];
    let (mut head, mut tail) = (0, 1);
    seen[0] = true;
    while head < tail {
        let vertex = queue[head]; head += 1;
        for other in 0..n {
            if adjacency[vertex][other] != 0 && !seen[other] {
                seen[other] = true;
                queue[tail] = other;
                tail += 1;
            }
        }
    }
    if tail != n { return -1; }
    let bytes = 8 * n * n;
    if output.is_null() || capacity < bytes { return -2; }
    let result = distances(&adjacency, n);
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for i in 0..n {
        for j in 0..n {
            let offset = 8 * (i * n + j);
            destination[offset..offset + 8].copy_from_slice(&result[i][j].to_le_bytes());
        }
    }
    bytes as i64
}
