const MAX_VERTICES: usize = 7;
const MAX_EDGES: usize = 9;
const MAX_INPUT_LENGTH: usize = 20;
const MODULUS: i64 = 998_244_353;

fn modular_power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = (result * base) % MODULUS;
        }
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn counting_eulerian_circuits(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    if n_value < 1 || n_value > MAX_VERTICES as i64 || m_value < 1 || m_value > MAX_EDGES as i64 {
        return -1;
    }
    let n = n_value as usize;
    let edge_count = m_value as usize;
    if length != 2 + 2 * edge_count {
        return -1;
    }

    let mut indegree = [0_usize; MAX_VERTICES];
    let mut outdegree = [0_usize; MAX_VERTICES];
    let mut start = 0_usize;
    for edge in 0..edge_count {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value {
            return -1;
        }
        let (u, v) = (u_value as usize, v_value as usize);
        if edge == 0 {
            start = u;
        }
        outdegree[u] += 1;
        indegree[v] += 1;
    }

    let balanced = (0..n).all(|vertex| indegree[vertex] == outdegree[vertex]);
    let mut answer = 0_i64;
    if balanced {
        let mut active_id = [MAX_VERTICES; MAX_VERTICES];
        let mut active_count = 0_usize;
        for vertex in 0..n {
            if indegree[vertex] != 0 {
                active_id[vertex] = active_count;
                active_count += 1;
            }
        }
        let root_id = active_id[start];
        let dimension = active_count - 1;
        let mut matrix = [[0_i64; MAX_VERTICES]; MAX_VERTICES];
        for edge in 0..edge_count {
            let u = values[2 + 2 * edge] as usize;
            let v = values[3 + 2 * edge] as usize;
            if u == start {
                continue;
            }
            let row = if active_id[u] > root_id { active_id[u] - 1 } else { active_id[u] };
            matrix[row][row] = (matrix[row][row] + 1) % MODULUS;
            if v != start {
                let column = if active_id[v] > root_id { active_id[v] - 1 } else { active_id[v] };
                matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS;
            }
        }

        let mut determinant = 1_i64;
        for column in 0..dimension {
            let mut pivot = column;
            while pivot < dimension && matrix[pivot][column] == 0 {
                pivot += 1;
            }
            if pivot == dimension {
                determinant = 0;
                break;
            }
            if pivot != column {
                matrix.swap(pivot, column);
                determinant = (MODULUS - determinant) % MODULUS;
            }
            let pivot_value = matrix[column][column];
            determinant = (determinant * pivot_value) % MODULUS;
            let inverse = modular_power(pivot_value, MODULUS - 2);
            for row in column + 1..dimension {
                let factor = (matrix[row][column] * inverse) % MODULUS;
                for j in column..dimension {
                    matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % MODULUS + MODULUS) % MODULUS;
                }
            }
        }
        answer = determinant;
        for &degree in outdegree.iter().take(n) {
            for factor in 2..degree {
                answer = (answer * factor as i64) % MODULUS;
            }
        }
    }

    if output.is_null() || output_capacity < 8 {
        return -2;
    }
    let encoded = answer as u64;
    for byte in 0..8 {
        unsafe { *output.add(byte) = (encoded >> (8 * byte)) as u8; }
    }
    8
}
