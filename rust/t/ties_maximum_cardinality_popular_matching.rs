// Bounded clean-room tied-list maximum-cardinality popular matching.
const A: usize = 4;
const P: usize = 4;
const R: usize = 8;
const INPUT_MAX: usize = 52;
const NODES: usize = 12;

fn augment(a: usize, right_count: usize, edges: &[[bool; R]; A],
           left: &mut [i32; A], right: &mut [i32; R], seen: &mut [bool; R]) -> bool {
    for p in 0..right_count {
        if !edges[a][p] || seen[p] { continue; }
        seen[p] = true;
        let previous = right[p];
        if previous < 0 || augment(previous as usize, right_count, edges, left, right, seen) {
            right[p] = a as i32;
            left[a] = p as i32;
            return true;
        }
    }
    false
}

fn maximum_matching(applicants: usize, right_count: usize, edges: &[[bool; R]; A],
                    initial: Option<&[i32; A]>) -> Option<([i32; A], [i32; R])> {
    let mut left = initial.copied().unwrap_or([-1; A]);
    let mut right = [-1i32; R];
    for a in 0..applicants {
        if left[a] >= 0 {
            let p = left[a] as usize;
            if p >= right_count || right[p] >= 0 || !edges[a][p] { return None; }
            right[p] = a as i32;
        }
    }
    loop {
        let mut changed = false;
        for a in 0..applicants {
            if left[a] < 0 {
                let mut seen = [false; R];
                if augment(a, right_count, edges, &mut left, &mut right, &mut seen) { changed = true; }
            }
        }
        if !changed { return Some((left, right)); }
    }
}

fn solve(applicants: usize, posts: usize, ranks: &[[i32; P]; A], max_rank: &[i32; A]) -> i64 {
    let right_count = posts + applicants;
    let mut first_edges = [[false; R]; A];
    for a in 0..applicants { for p in 0..posts { first_edges[a][p] = ranks[a][p] == 1; }}
    let (first_left, first_right) = match maximum_matching(applicants, right_count, &first_edges, None) {
        Some(value) => value, None => return 0,
    };
    let first_size = first_left[..applicants].iter().filter(|&&p| p >= 0).count();

    let mut state = [-1i32; NODES];
    let mut queue = [0usize; NODES];
    let mut tail = 0;
    for a in 0..applicants { if first_left[a] < 0 { state[a] = 0; queue[tail] = a; tail += 1; }}
    for p in 0..posts { if first_right[p] < 0 { let node = applicants + p; state[node] = 0; queue[tail] = node; tail += 1; }}
    for a in 0..applicants { let node = applicants + posts + a; state[node] = 0; queue[tail] = node; tail += 1; }
    let mut head = 0;
    while head < tail {
        let node = queue[head]; head += 1;
        if node < applicants {
            let a = node;
            if state[node] == 0 {
                for p in 0..posts { if ranks[a][p] == 1 && first_left[a] != p as i32 {
                    let target = applicants + p;
                    if state[target] < 0 { state[target] = 1; queue[tail] = target; tail += 1; }
                }}
            } else if first_left[a] >= 0 {
                let target = applicants + first_left[a] as usize;
                if state[target] < 0 { state[target] = 0; queue[tail] = target; tail += 1; }
            }
        } else {
            let p = node - applicants;
            if p < posts {
                if state[node] == 0 {
                    for a in 0..applicants { if ranks[a][p] == 1 && first_left[a] != p as i32 && state[a] < 0 {
                        state[a] = 1; queue[tail] = a; tail += 1;
                    }}
                } else if first_right[p] >= 0 {
                    let target = first_right[p] as usize;
                    if state[target] < 0 { state[target] = 0; queue[tail] = target; tail += 1; }
                }
            }
        }
    }
    let mut classes = [2i32; NODES];
    for i in 0..applicants + right_count { classes[i] = if state[i] < 0 { 2 } else { state[i] }; }
    let mut allowed = [[false; R]; A];
    for a in 0..applicants {
        let mut best_even = posts as i32 + 1;
        for p in 0..posts { if ranks[a][p] > 0 && classes[applicants + p] == 0 {
            best_even = best_even.min(ranks[a][p]);
        }}
        let last_rank = max_rank[a] + 1;
        if classes[applicants + posts + a] == 0 { best_even = best_even.min(last_rank); }
        for p in 0..posts {
            let rank = ranks[a][p];
            if rank != 1 && !(rank > 0 && rank == best_even && classes[applicants + p] == 0) { continue; }
            let ac = classes[a]; let pc = classes[applicants + p];
            if (ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1) { continue; }
            allowed[a][p] = true;
        }
        if last_rank == best_even && classes[applicants + posts + a] == 0 {
            let p = posts + a; let ac = classes[a]; let pc = classes[applicants + p];
            if !((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) { allowed[a][p] = true; }
        }
    }
    for a in 0..applicants { if first_left[a] >= 0 && !allowed[a][first_left[a] as usize] { return 0; }}

    let (popular_left, _) = match maximum_matching(applicants, right_count, &allowed, Some(&first_left)) {
        Some(value) => value, None => return 0,
    };
    if popular_left[..applicants].iter().any(|&p| p < 0) { return 0; }
    let popular_rank_one = (0..applicants).filter(|&a| {
        let p = popular_left[a] as usize; p < posts && ranks[a][p] == 1
    }).count();
    if popular_rank_one != first_size { return 0; }

    let mut real_edges = [[false; R]; A];
    let mut initial_real = [-1i32; A];
    for a in 0..applicants {
        if (popular_left[a] as usize) < posts { initial_real[a] = popular_left[a]; }
        for p in 0..posts { real_edges[a][p] = allowed[a][p]; }
    }
    let (real_left, _) = match maximum_matching(applicants, right_count, &real_edges, Some(&initial_real)) {
        Some(value) => value, None => return 0,
    };
    let real_rank_one = (0..applicants).filter(|&a| {
        let p = real_left[a]; p >= 0 && (p as usize) < posts && ranks[a][p as usize] == 1
    }).count();
    if real_rank_one != first_size { return 0; }
    let (final_left, _) = match maximum_matching(applicants, right_count, &allowed, Some(&real_left)) {
        Some(value) => value, None => return 0,
    };
    if final_left[..applicants].iter().any(|&p| p < 0) { return 0; }
    let mut result = 0;
    let mut final_rank_one = 0;
    for a in 0..applicants {
        let p = final_left[a] as usize;
        if p < posts { result += 1; if ranks[a][p] == 1 { final_rank_one += 1; }}
    }
    if final_rank_one != first_size { return 0; }
    result
}

#[no_mangle]
pub unsafe extern "C" fn ties_maximum_cardinality_popular_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > INPUT_MAX { return -1; }
    let av = *input; let pv = *input.add(1); let ev = *input.add(2);
    if av < 1 || av > A as i64 || pv < 1 || pv > P as i64 || ev < av || ev > av * pv { return -1; }
    let applicants = av as usize; let posts = pv as usize; let edge_count = ev as usize;
    if length != 3 + 3 * edge_count { return -1; }
    let mut ranks = [[0i32; P]; A];
    let mut max_rank = [0i32; A];
    let mut cursor = 3;
    for _ in 0..edge_count {
        let a64 = *input.add(cursor); let p64 = *input.add(cursor + 1); let r64 = *input.add(cursor + 2); cursor += 3;
        if a64 < 0 || a64 >= applicants as i64 || p64 < 0 || p64 >= posts as i64 || r64 < 1 || r64 > posts as i64 { return -1; }
        let a = a64 as usize; let p = p64 as usize; let rank = r64 as i32;
        if ranks[a][p] != 0 { return -1; }
        ranks[a][p] = rank; max_rank[a] = max_rank[a].max(rank);
    }
    let mut has_tie = false;
    for a in 0..applicants {
        if max_rank[a] == 0 { return -1; }
        let mut counts = [0i32; P + 1];
        for p in 0..posts { if ranks[a][p] > 0 { counts[ranks[a][p] as usize] += 1; }}
        for rank in 1..=max_rank[a] as usize { if counts[rank] == 0 { return -1; } if counts[rank] > 1 { has_tie = true; }}
    }
    if !has_tie { return -1; }
    solve(applicants, posts, &ranks, &max_rank)
}
