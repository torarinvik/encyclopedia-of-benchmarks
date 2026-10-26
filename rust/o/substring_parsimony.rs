const MAX_STATES: usize = 4;
const MAX_INPUT: usize = 26;
const MAX_ASSIGNMENTS: usize = 1024;
const MAX_OUTPUT_WORDS: usize = 2 + 5 * MAX_ASSIGNMENTS;
const INF: i64 = 1_000_000;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn substring_parsimony(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 10 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let q_raw = values[0];
    let threshold = values[1];
    if q_raw < 1 || q_raw > MAX_STATES as i64 || threshold < 0 || threshold > 36 { return -1; }
    let q = q_raw as usize;
    if length != 9 + q * q { return -1; }
    let child = [[values[2], values[3]], [values[4], values[5]]];
    for node in 0..2 {
        if child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
            || child[node][0] == child[node][1] { return -1; }
    }
    let root_leaf = if child[0][0] == 1 { child[0][1] }
        else if child[0][1] == 1 { child[0][0] }
        else { -1 };
    if root_leaf < 2 || root_leaf > 4 { return -1; }
    if child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
        || child[1][0] == child[1][1] || child[1][0] == root_leaf || child[1][1] == root_leaf { return -1; }
    for leaf in 2..=4 {
        if leaf != root_leaf && child[1][0] != leaf && child[1][1] != leaf { return -1; }
    }
    let mut masks = [0i64; 3];
    let universe = (1u64 << q) - 1;
    for leaf in 0..3 {
        masks[leaf] = values[6 + leaf];
        if masks[leaf] <= 0 || masks[leaf] as u64 > universe { return -1; }
    }
    let mut distance = [[0i64; MAX_STATES]; MAX_STATES];
    for i in 0..q {
        for j in 0..q {
            let value = values[9 + i * q + j];
            if value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0) { return -1; }
            distance[i][j] = value;
            if value != values[9 + j * q + i] { return -1; }
        }
    }
    for i in 0..q {
        for j in 0..q {
            for k in 0..q {
                if distance[i][k] > distance[i][j] + distance[j][k] { return -1; }
            }
        }
    }
    let mut dp = [[INF; MAX_STATES]; 5];
    for leaf in 2..=4 {
        for state in 0..q {
            if (masks[leaf - 2] as u64 & (1u64 << state)) != 0 { dp[leaf][state] = 0; }
        }
    }
    for node in (0..=1).rev() {
        for state in 0..q {
            let mut total = 0;
            for slot in 0..2 {
                let descendant = child[node][slot] as usize;
                let mut best = INF;
                for other in 0..q {
                    let candidate = dp[descendant][other] + distance[state][other];
                    if candidate < best { best = candidate; }
                }
                total += best;
            }
            dp[node][state] = total;
        }
    }
    let mut optimum = INF;
    for state in 0..q { if dp[0][state] < optimum { optimum = dp[0][state]; } }
    if optimum >= INF { return -1; }
    let mut staged = [0i64; MAX_OUTPUT_WORDS];
    staged[0] = optimum;
    let mut words = 2usize;
    if optimum <= threshold {
        for x0 in 0..q {
            for x1 in 0..q {
                for x2 in 0..q {
                    if masks[0] as u64 & (1u64 << x2) == 0 { continue; }
                    for x3 in 0..q {
                        if masks[1] as u64 & (1u64 << x3) == 0 { continue; }
                        for x4 in 0..q {
                            if masks[2] as u64 & (1u64 << x4) == 0 { continue; }
                            let label = [x0, x1, x2, x3, x4];
                            let mut score = 0;
                            for node in 0..2 {
                                for slot in 0..2 {
                                    score += distance[label[node]][label[child[node][slot] as usize]];
                                }
                            }
                            if score == optimum {
                                for node in 0..5 { staged[words] = label[node] as i64; words += 1; }
                            }
                        }
                    }
                }
            }
        }
    }
    staged[1] = ((words - 2) / 5) as i64;
    let bytes = words * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for word in 0..words { store_i64_le(output, word * 8, staged[word]); }
    bytes as i64
}
