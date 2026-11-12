const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 12;
const MAX_INPUT_LENGTH: usize = 26;
const MAX_OUTPUT_BYTES: usize = 96;

#[no_mangle]
pub unsafe extern "C" fn counting_c4(
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
    if n_value < 2 || n_value > MAX_VERTICES as i64 || m_value < 1 || m_value > MAX_EDGES as i64 {
        return -1;
    }
    let n = n_value as usize;
    let edge_count = m_value as usize;
    if length != 2 + 2 * edge_count {
        return -1;
    }

    let mut multiplicity = [[0_i64; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..edge_count {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value {
            return -1;
        }
        let (u, v) = (u_value as usize, v_value as usize);
        multiplicity[u][v] += 1;
        multiplicity[v][u] += 1;
    }

    let mut answers = [0_u64; MAX_EDGES];
    for edge in 0..edge_count {
        let u = values[2 + 2 * edge] as usize;
        let v = values[3 + 2 * edge] as usize;
        for a in 0..n {
            if a == u || a == v { continue; }
            for b in 0..n {
                if b == u || b == v || b == a { continue; }
                answers[edge] += (multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v]) as u64;
            }
        }
    }

    let bytes = 8 * edge_count;
    if output.is_null() || output_capacity < bytes {
        return -2;
    }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for edge in 0..edge_count {
        for byte in 0..8 {
            staged[8 * edge + byte] = (answers[edge] >> (8 * byte)) as u8;
        }
    }
    for byte in 0..bytes {
        unsafe { *output.add(byte) = staged[byte]; }
    }
    bytes as i64
}
