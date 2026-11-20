const INF: i64 = 1_i64 << 60;

#[no_mangle]
pub unsafe extern "C" fn minimum_cost_bipartite_edge_cover_subset_dp(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || !(2..=67).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let left_count = values[0];
    let right_count = values[1];
    if !(1..=8).contains(&left_count) || !(1..=8).contains(&right_count) { return -1; }
    let (left_count, right_count) = (left_count as usize, right_count as usize);
    if length != 2 + left_count * right_count { return -1; }
    if values[2..].iter().any(|&cost| !(0..=1000).contains(&cost)) { return -1; }

    let states = 1usize << right_count;
    let mut current = [INF; 256];
    let mut following = [INF; 256];
    let mut subset_cost = [0_i64; 256];
    current[0] = 0;
    for left in 0..left_count {
        subset_cost[0] = 0;
        for subset in 1..states {
            let bit = subset & subset.wrapping_neg();
            let right = bit.trailing_zeros() as usize;
            subset_cost[subset] = subset_cost[subset ^ bit] + values[2 + left * right_count + right];
        }
        following[..states].fill(INF);
        for covered in 0..states {
            if current[covered] == INF { continue; }
            for selected in 1..states {
                let combined = covered | selected;
                let candidate = current[covered] + subset_cost[selected];
                if candidate < following[combined] { following[combined] = candidate; }
            }
        }
        current[..states].copy_from_slice(&following[..states]);
    }
    current[states - 1]
}
