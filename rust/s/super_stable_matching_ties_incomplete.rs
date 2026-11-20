const MAX_N: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 34;

fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > MAX_PARSEABLE_LENGTH { return -1; }
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if values.len() != 1 + 2 * n * n { return -1; }
    let side = n * n;
    let mut men_rank = [[0i64; MAX_N]; MAX_N];
    let mut women_rank = [[0i64; MAX_N]; MAX_N];
    for man in 0..n {
        for woman in 0..n {
            let rank = values[1 + man * n + woman];
            if rank < 0 || rank > n as i64 { return -1; }
            men_rank[man][woman] = rank;
        }
    }
    for woman in 0..n {
        for man in 0..n {
            let rank = values[1 + side + woman * n + man];
            if rank < 0 || rank > n as i64
                || ((rank > 0) != (men_rank[man][woman] > 0)) { return -1; }
            women_rank[woman][man] = rank;
        }
    }
    for man in 0..n {
        let maximum = *men_rank[man][..n].iter().max().unwrap();
        for level in 1..=maximum {
            if !men_rank[man][..n].contains(&level) { return -1; }
        }
        let maximum = *women_rank[man][..n].iter().max().unwrap();
        for level in 1..=maximum {
            if !women_rank[man][..n].contains(&level) { return -1; }
        }
    }

    let mut alive = [[false; MAX_N]; MAX_N];
    let mut engaged = [[false; MAX_N]; MAX_N];
    let mut proposed = [false; MAX_N];
    for man in 0..n {
        for woman in 0..n { alive[man][woman] = men_rank[man][woman] > 0; }
    }
    loop {
        let mut proposer = None;
        for man in 0..n {
            let has_engagement = engaged[man][..n].iter().any(|&value| value);
            let has_choice = (0..n).any(|woman| alive[man][woman]);
            if !has_engagement && has_choice {
                proposer = Some(man);
                break;
            }
        }
        let Some(man) = proposer else { break; };
        let head_rank = (0..n).filter(|&woman| alive[man][woman])
            .map(|woman| men_rank[man][woman]).min().unwrap();
        for woman in 0..n {
            if !alive[man][woman] || men_rank[man][woman] != head_rank {
                continue;
            }
            proposed[woman] = true;
            engaged[man][woman] = true;
            for successor in 0..n {
                if alive[successor][woman]
                    && women_rank[woman][successor] > women_rank[woman][man] {
                    engaged[successor][woman] = false;
                    alive[successor][woman] = false;
                }
            }
        }
        for woman in 0..n {
            let count = (0..n).filter(|&man| engaged[man][woman]).count();
            if count > 1 {
                for man in 0..n { engaged[man][woman] = false; }
                let tail = (0..n).filter(|&man| alive[man][woman])
                    .map(|man| women_rank[woman][man]).max().unwrap_or(0);
                for man in 0..n {
                    if alive[man][woman] && women_rank[woman][man] == tail {
                        alive[man][woman] = false;
                    }
                }
            }
        }
    }

    let base = (n + 1) as i64;
    let limit = base.pow(n as u32);
    let mut best_code = 0i64;
    let mut best_size = -1i64;
    for code in 0..limit {
        let mut used = 0usize;
        let mut size = 0i64;
        let mut valid = true;
        let mut place = limit / base;
        for man in 0..n {
            let woman = ((code / place) % base) as usize;
            if woman < n {
                if !engaged[man][woman] || (used & (1 << woman)) != 0 { valid = false; }
                used |= 1 << woman;
                size += 1;
            }
            if man + 1 < n { place /= base; }
        }
        if valid && size > best_size {
            best_size = size;
            best_code = code;
        }
    }
    let mut matched = [false; MAX_N];
    let mut place = limit / base;
    for _man in 0..n {
        let woman = ((best_code / place) % base) as usize;
        if woman < n { matched[woman] = true; }
        if place > 1 { place /= base; }
    }
    for woman in 0..n {
        if proposed[woman] && !matched[woman] { return -2; }
    }
    best_code
}

#[no_mangle]
pub unsafe extern "C" fn super_stable_matching_ties_incomplete(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
