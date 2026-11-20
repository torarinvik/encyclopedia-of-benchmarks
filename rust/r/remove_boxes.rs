const MAX_BOXES: usize = 18;
const MAX_PARSEABLE_LENGTH: usize = MAX_BOXES + 2;

type Memo = [[[i64; MAX_BOXES + 1]; MAX_BOXES]; MAX_BOXES];

fn solve_boxes(left: usize, right: usize, carry: usize, colors: &[i64; MAX_BOXES],
               counts: &[usize; MAX_BOXES], memo: &mut Memo) -> i64 {
    if left > right { return 0; }
    if memo[left][right][carry] >= 0 { return memo[left][right][carry]; }
    let attached = counts[left] + carry;
    let mut best = (attached * attached) as i64
        + solve_boxes(left + 1, right, 0, colors, counts, memo);
    for later in left + 1..=right {
        if colors[later] == colors[left] {
            let joined = solve_boxes(left + 1, later - 1, 0, colors, counts, memo)
                + solve_boxes(later, right, attached, colors, counts, memo);
            best = best.max(joined);
        }
    }
    memo[left][right][carry] = best;
    best
}

#[no_mangle]
pub unsafe extern "C" fn remove_boxes(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_BOXES as i64 { return -1; }
    let n = input[0] as usize;
    if length != n + 1 { return -1; }
    let mut colors = [0_i64; MAX_BOXES];
    let mut counts = [0_usize; MAX_BOXES];
    let mut groups = 0;
    for index in 0..n {
        let color = input[index + 1];
        if !(0..=7).contains(&color) { return -1; }
        if groups > 0 && colors[groups - 1] == color {
            counts[groups - 1] += 1;
        } else {
            colors[groups] = color;
            counts[groups] = 1;
            groups += 1;
        }
    }
    if groups == 0 { return 0; }
    let mut memo: Memo = [[[-1; MAX_BOXES + 1]; MAX_BOXES]; MAX_BOXES];
    solve_boxes(0, groups - 1, 0, &colors, &counts, &mut memo)
}
