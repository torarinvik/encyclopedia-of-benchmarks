//! Uncompiled exact-length shortest-walk draft.
const INF: i64 = 1_000_000_000_000_000;

#[no_mangle]
pub unsafe extern "C" fn fixed_length_walk_minplus(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=261).contains(&length) { return -100_000_002; }
    let frame = unsafe { std::slice::from_raw_parts(input, length) };
    let (nv, mut k, source, target) = (frame[0], frame[1], frame[2], frame[3]);
    if !(1..=16).contains(&nv) || !(0..=1_000_000).contains(&k)
        || source < 0 || source >= nv || target < 0 || target >= nv
        || length != 4 + (nv * nv) as usize { return -100_000_002; }
    let n = nv as usize;
    let mut matrix = [[INF; 16]; 16];
    let mut distance = [INF; 16];
    distance[source as usize] = 0;
    for i in 0..n {
        for j in 0..n {
            let weight = frame[4 + i*n + j];
            if weight != 1_000_000 && !(-100..=100).contains(&weight) { return -100_000_002; }
            if weight != 1_000_000 { matrix[i][j] = weight; }
        }
    }
    while k != 0 {
        if k & 1 != 0 {
            let mut next = [INF; 16];
            for j in 0..n {
                for i in 0..n {
                    if distance[i] != INF && matrix[i][j] != INF {
                        next[j] = next[j].min(distance[i] + matrix[i][j]);
                    }
                }
            }
            distance = next;
        }
        k >>= 1;
        if k != 0 {
            let mut next = [[INF; 16]; 16];
            for i in 0..n {
                for j in 0..n {
                    for p in 0..n {
                        if matrix[i][p] != INF && matrix[p][j] != INF {
                            next[i][j] = next[i][j].min(matrix[i][p] + matrix[p][j]);
                        }
                    }
                }
            }
            matrix = next;
        }
    }
    if distance[target as usize] == INF { -100_000_001 } else { distance[target as usize] }
}
