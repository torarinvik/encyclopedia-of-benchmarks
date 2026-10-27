const MAX_A: usize = 4;
const MAX_P: usize = 4;
const MAX_POSTS: usize = 8;
const MAX_NODES: usize = 12;
const MAX_INPUT: usize = 51;
const MAX_OUTPUT: usize = 40;

unsafe fn put64(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

fn lex_less(left: &[usize; MAX_A], right: &[usize; MAX_A], count: usize) -> bool {
    for index in 0..count {
        if left[index] != right[index] { return left[index] < right[index]; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn ranked_matching_popular_matching(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let a64 = *input;
    let p64 = *input.add(1);
    let e64 = *input.add(2);
    if a64 < 1 || a64 > MAX_A as i64 || p64 < 1 || p64 > MAX_P as i64 { return -1; }
    let applicants = a64 as usize;
    let posts = p64 as usize;
    if e64 < applicants as i64 || e64 > (applicants * posts) as i64 { return -1; }
    let edges = e64 as usize;
    if length != 3 + 3 * edges { return -1; }
    let post_count = posts + applicants;
    let node_count = applicants + post_count;
    let output_bytes = 8 * (applicants + 1);
    let mut rank = [[0i64; MAX_P]; MAX_A];
    let mut rank_seen = [[false; MAX_P + 1]; MAX_A];
    let mut max_rank = [0usize; MAX_A];
    for edge in 0..edges {
        let at = 3 + edge * 3;
        let av = *input.add(at);
        let pv = *input.add(at + 1);
        let rv = *input.add(at + 2);
        if av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > p64 { return -1; }
        let (a, p, r) = (av as usize, pv as usize, rv as usize);
        if rank[a][p] != 0 { return -1; }
        rank[a][p] = rv;
        rank_seen[a][r] = true;
        max_rank[a] = max_rank[a].max(r);
    }
    for a in 0..applicants {
        if max_rank[a] == 0 { return -1; }
        for r in 1..=max_rank[a] { if !rank_seen[a][r] { return -1; } }
    }

    let mut best_m1 = [0usize; MAX_A];
    let mut best_m1_size: i64 = -1;
    let mut m1_limit = 1usize;
    for _ in 0..applicants { m1_limit *= posts + 1; }
    for code in 0..m1_limit {
        let mut value = code;
        let mut candidate = [0usize; MAX_A];
        let mut used = 0u16;
        let mut count = 0i64;
        let mut valid = true;
        for a in 0..applicants {
            let p = value % (posts + 1);
            value /= posts + 1;
            candidate[a] = p;
            if p == posts { continue; }
            if rank[a][p] != 1 || (used & (1u16 << p)) != 0 { valid = false; break; }
            used |= 1u16 << p;
            count += 1;
        }
        if valid && (count > best_m1_size || (count == best_m1_size && lex_less(&candidate, &best_m1, applicants))) {
            best_m1_size = count;
            best_m1 = candidate;
        }
    }

    let mut mate_a = [-1i64; MAX_A];
    let mut mate_p = [-1i64; MAX_P];
    for a in 0..applicants {
        if best_m1[a] < posts {
            mate_a[a] = best_m1[a] as i64;
            mate_p[best_m1[a]] = a as i64;
        }
    }
    let mut parity = [-1i8; MAX_NODES];
    let mut queue = [0usize; MAX_NODES];
    let (mut head, mut tail) = (0usize, 0usize);
    for a in 0..applicants {
        if mate_a[a] < 0 { parity[a] = 0; queue[tail] = a; tail += 1; }
    }
    for p in 0..posts {
        if mate_p[p] < 0 { let node = applicants + p; parity[node] = 0; queue[tail] = node; tail += 1; }
    }
    for p in posts..post_count {
        let node = applicants + p; parity[node] = 0; queue[tail] = node; tail += 1;
    }
    while head < tail {
        let node = queue[head]; head += 1;
        if node < applicants {
            let a = node;
            if parity[node] == 0 {
                for p in 0..posts {
                    if rank[a][p] == 1 && mate_a[a] != p as i64 {
                        let target = applicants + p;
                        if parity[target] < 0 { parity[target] = 1; queue[tail] = target; tail += 1; }
                    }
                }
            } else if mate_a[a] >= 0 {
                let target = applicants + mate_a[a] as usize;
                if parity[target] < 0 { parity[target] = 0; queue[tail] = target; tail += 1; }
            }
        } else {
            let p = node - applicants;
            if p < posts {
                if parity[node] == 0 {
                    for a in 0..applicants {
                        if rank[a][p] == 1 && mate_a[a] != p as i64 && parity[a] < 0 {
                            parity[a] = 1; queue[tail] = a; tail += 1;
                        }
                    }
                } else if mate_p[p] >= 0 {
                    let target = mate_p[p] as usize;
                    if parity[target] < 0 { parity[target] = 0; queue[tail] = target; tail += 1; }
                }
            }
        }
    }
    let mut class_of = [2i8; MAX_NODES];
    for node in 0..node_count { if parity[node] >= 0 { class_of[node] = parity[node]; } }
    let mut reduced = [[false; MAX_POSTS]; MAX_A];
    let mut allowed = [[false; MAX_POSTS]; MAX_A];
    for a in 0..applicants {
        let mut best_even_rank = posts + 1;
        for p in 0..posts {
            if rank[a][p] == 1 { reduced[a][p] = true; }
            if rank[a][p] > 0 && class_of[applicants + p] == 0 {
                best_even_rank = best_even_rank.min(rank[a][p] as usize);
            }
        }
        let last_rank = max_rank[a] + 1;
        if class_of[applicants + posts + a] == 0 { best_even_rank = best_even_rank.min(last_rank); }
        for p in 0..posts {
            if rank[a][p] > 0 && rank[a][p] as usize == best_even_rank && class_of[applicants + p] == 0 {
                reduced[a][p] = true;
            }
        }
        if last_rank == best_even_rank && class_of[applicants + posts + a] == 0 { reduced[a][posts + a] = true; }
        for p in 0..post_count {
            let ca = class_of[a];
            let cp = class_of[applicants + p];
            if reduced[a][p] && !((ca == 1 && (cp == 1 || cp == 2)) || (ca == 2 && cp == 1)) {
                allowed[a][p] = true;
            }
        }
    }
    let mut best = [0usize; MAX_A];
    let mut found = false;
    let mut full_limit = 1usize;
    for _ in 0..applicants { full_limit *= post_count; }
    for code in 0..full_limit {
        let mut value = code;
        let mut candidate = [0usize; MAX_A];
        let mut used = 0u16;
        let mut first_count = 0i64;
        let mut valid = true;
        for a in 0..applicants {
            let p = value % post_count;
            value /= post_count;
            candidate[a] = p;
            if !allowed[a][p] || (used & (1u16 << p)) != 0 { valid = false; break; }
            used |= 1u16 << p;
            if p < posts && rank[a][p] == 1 { first_count += 1; }
        }
        if valid && first_count == best_m1_size && (!found || lex_less(&candidate, &best, applicants)) {
            found = true;
            best = candidate;
        }
    }
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put64(staged.as_mut_ptr(), 0, if found { 1 } else { 0 });
    for a in 0..applicants { put64(staged.as_mut_ptr(), 8 * (a + 1), if found { best[a] as i64 } else { -1 }); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
