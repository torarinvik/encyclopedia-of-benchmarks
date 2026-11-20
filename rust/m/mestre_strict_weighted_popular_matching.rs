// Clean-room bounded implementation of Mestre's strict weighted profile.
const A: usize = 4;
const J: usize = 5;
const N: usize = 9;
const PARSEABLE: usize = 31;
const INF: i64 = 1_000_000_000;

fn lambda_min(a: usize, target: usize, rows: &[[usize; N]; A], row_len: &[usize; A],
              f_category: &[i32; N], label: &[i64; N]) -> i64 {
    let mut best = INF;
    for &job in rows[a].iter().take(row_len[a]) {
        if job == target { break; }
        if f_category[job] >= 0 { best = best.min(label[job]); }
    }
    best
}

fn augment(a: usize, edges: &[[usize; 2]; A], edge_count: &[usize; A],
           owner: &mut [i32; N], seen: &mut [bool; N]) -> bool {
    for i in 0..edge_count[a] {
        let job = edges[a][i];
        if seen[job] { continue; }
        seen[job] = true;
        let previous = owner[job];
        if previous < 0 || augment(previous as usize, edges, edge_count, owner, seen) {
            owner[job] = a as i32;
            return true;
        }
    }
    false
}

fn solve(applicants: usize, jobs: usize, weights: &[i64; A], lengths: &[usize; A],
         listed: &[[usize; J]; A]) -> i64 {
    let mut rows = [[0usize; N]; A];
    let mut row_len = [0usize; A];
    for a in 0..applicants {
        for i in 0..lengths[a] { rows[a][row_len[a]] = listed[a][i]; row_len[a] += 1; }
        rows[a][row_len[a]] = jobs + a; row_len[a] += 1;
    }
    let mut categories = [0i64; A];
    let mut category_count = 0;
    for &w in weights.iter().take(applicants) {
        if !categories[..category_count].contains(&w) { categories[category_count] = w; category_count += 1; }
    }
    categories[..category_count].sort_by(|x, y| y.cmp(x));
    let mut category = [0usize; A];
    for a in 0..applicants {
        category[a] = categories[..category_count].iter().position(|&w| w == weights[a]).unwrap();
    }
    let mut first = [0usize; A];
    let mut second = [N; A];
    let mut f_category = [-1i32; N];
    let mut higher = [false; N];
    for c in 0..category_count {
        for a in 0..applicants { if category[a] == c {
            for &p in rows[a].iter().take(row_len[a]) { if !higher[p] { first[a] = p; break; } }
        }}
        for a in 0..applicants { if category[a] == c {
            f_category[first[a]] = c as i32; higher[first[a]] = true;
        }}
    }
    for a in 0..applicants {
        for &p in rows[a].iter().take(row_len[a]) {
            if f_category[p] < 0 || f_category[p] as usize > category[a] { second[a] = p; break; }
        }
    }
    let mut label = [INF; N];
    let mut keep_first = [true; A];
    let mut keep_second = [false; A];
    for a in 0..applicants { keep_second[a] = second[a] != N; }
    for c in 0..category_count {
        let weight = categories[c];
        if c == 0 {
            for a in 0..applicants { if category[a] == c { label[first[a]] = weight; } }
            continue;
        }
        for a in 0..applicants {
            if category[a] == c && lambda_min(a, first[a], &rows, &row_len, &f_category, &label) < weight { return 0; }
        }
        for p in 0..N { if f_category[p] == c as i32 {
            let group: Vec<usize> = (0..applicants).filter(|&a| category[a] == c && first[a] == p).collect();
            if group.len() == 1 {
                let earlier = lambda_min(group[0], p, &rows, &row_len, &f_category, &label);
                label[p] = if earlier >= INF { weight } else { weight.min(earlier - weight) };
            } else {
                label[p] = weight;
                for a in group {
                    if lambda_min(a, p, &rows, &row_len, &f_category, &label) < 2 * weight { keep_first[a] = false; }
                }
            }
        }}
        for a in 0..applicants {
            if category[a] == c && second[a] != N
                && lambda_min(a, second[a], &rows, &row_len, &f_category, &label) < weight { keep_second[a] = false; }
        }
    }
    let mut is_first = [false; N];
    for a in 0..applicants { is_first[first[a]] = true; }
    for p in 0..N {
        if is_first[p] && !(0..applicants).any(|a| first[a] == p && keep_first[a]) { return 0; }
    }
    let mut edges = [[0usize; 2]; A];
    let mut edge_count = [0usize; A];
    for a in 0..applicants {
        if keep_first[a] { edges[a][edge_count[a]] = first[a]; edge_count[a] += 1; }
        if keep_second[a] && second[a] != N && !is_first[second[a]] {
            edges[a][edge_count[a]] = second[a]; edge_count[a] += 1;
        }
        if edge_count[a] == 0 { return 0; }
    }
    let mut owner = [-1i32; N];
    for a in 0..applicants {
        let mut seen = [false; N];
        if !augment(a, &edges, &edge_count, &mut owner, &mut seen) { return 0; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn mestre_strict_weighted_popular_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > PARSEABLE { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (a64, j64) = (values[0], values[1]);
    if a64 < 1 || a64 > A as i64 || j64 < 1 || j64 > J as i64 { return -1; }
    let (applicants, jobs) = (a64 as usize, j64 as usize);
    if length < 2 + 2 * applicants { return -1; }
    let mut weights = [0i64; A];
    let mut lengths = [0usize; A];
    let mut total = 0usize;
    for a in 0..applicants {
        weights[a] = values[2 + a];
        let size = values[2 + applicants + a];
        if !(1..=1000).contains(&weights[a]) || size < 1 || size > jobs as i64 { return -1; }
        lengths[a] = size as usize; total += lengths[a];
    }
    if length != 2 + 2 * applicants + total { return -1; }
    let mut listed = [[0usize; J]; A];
    let mut cursor = 2 + 2 * applicants;
    for a in 0..applicants { for i in 0..lengths[a] {
        let value = values[cursor]; cursor += 1;
        if value < 0 || value >= jobs as i64 { return -1; }
        let p = value as usize;
        if listed[a][..i].contains(&p) { return -1; }
        listed[a][i] = p;
    }}
    solve(applicants, jobs, &weights, &lengths, &listed)
}
