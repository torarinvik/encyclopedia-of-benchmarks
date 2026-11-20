const MAX_N: usize = 9;
const MAX_INPUT_LENGTH: usize = 111;
const INF: i64 = 1i64 << 60;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() {
        unsafe { *output.add(byte) = *part; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_weight_cycle_floyd(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    if !(3..=MAX_N as i64).contains(&n_value)
        || m_value < 0
        || m_value > n_value * (n_value - 1) / 2
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 3 * m {
        return -1;
    }

    let mut edge = [[INF; MAX_N]; MAX_N];
    let mut dist = [[INF; MAX_N]; MAX_N];
    for i in 0..n {
        edge[i][i] = 0;
    }
    for e in 0..m {
        let offset = 2 + 3 * e;
        let u_value = values[offset];
        let v_value = values[offset + 1];
        let weight = values[offset + 2];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || u_value == v_value || !(1..=1000).contains(&weight)
        {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        if edge[u][v] != INF {
            return -1;
        }
        edge[u][v] = weight;
        edge[v][u] = weight;
    }
    if output.is_null() || capacity < 8 {
        return -2;
    }
    dist = edge;

    let mut best = INF;
    for k in 0..n {
        for i in 0..k {
            if edge[i][k] == INF {
                continue;
            }
            for j in (i + 1)..k {
                if edge[k][j] != INF && dist[i][j] != INF {
                    let candidate = edge[i][k] + edge[k][j] + dist[i][j];
                    if candidate < best {
                        best = candidate;
                    }
                }
            }
        }
        for i in 0..n {
            if dist[i][k] == INF {
                continue;
            }
            for j in 0..n {
                if dist[k][j] != INF {
                    let candidate = dist[i][k] + dist[k][j];
                    if candidate < dist[i][j] {
                        dist[i][j] = candidate;
                    }
                }
            }
        }
    }
    unsafe { store_i64_le(output, if best == INF { -1 } else { best }); }
    8
}
