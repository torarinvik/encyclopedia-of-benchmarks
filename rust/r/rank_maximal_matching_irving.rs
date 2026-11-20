use core::slice;

const MAX_A: usize = 4;
const MAX_P: usize = 4;
const MAX_V: usize = 8;
const MAX_RANK: usize = 4;
const MAX_INPUT: usize = 52;
const MAX_OUTPUT: usize = 40;

fn put_i64(output: &mut [u8; MAX_OUTPUT], at: usize, value: i64) {
    output[at..at + 8].copy_from_slice(&value.to_le_bytes());
}

fn lex_less(left: &[usize; MAX_A], right: &[usize; MAX_A], count: usize) -> bool {
    for i in 0..count {
        if left[i] != right[i] { return left[i] < right[i]; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn rank_maximal_matching_irving(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT).contains(&length) { return -1; }
    let values = slice::from_raw_parts(input, length);
    let (a64, p64, e64) = (values[0], values[1], values[2]);
    if !(1..=4).contains(&a64) || !(1..=4).contains(&p64) { return -1; }
    let (applicants, posts) = (a64 as usize, p64 as usize);
    if e64 < a64 || e64 > (applicants * posts) as i64 { return -1; }
    let edges = e64 as usize;
    if edges > 16 || length != 3 + 3 * edges { return -1; }

    let mut rank = [[0i64; MAX_P]; MAX_A];
    let mut degree = [0usize; MAX_A];
    let mut max_rank = 0usize;
    for edge in 0..edges {
        let at = 3 + 3 * edge;
        let (av, pv, rv) = (values[at], values[at + 1], values[at + 2]);
        if av < 0 || av >= a64 || pv < 0 || pv >= p64 || !(1..=4).contains(&rv) { return -1; }
        let (a, p) = (av as usize, pv as usize);
        if rank[a][p] != 0 { return -1; }
        rank[a][p] = rv;
        degree[a] += 1;
        max_rank = max_rank.max(rv as usize);
    }
    if degree[..applicants].contains(&0) { return -1; }

    let mut blocked = [[false; MAX_P]; MAX_A];
    let mut mate_a = [-1i32; MAX_A];
    let mut mate_p = [-1i32; MAX_P];
    for phase in 1..=max_rank {
        let mut limit = 1usize;
        for _ in 0..applicants { limit *= posts + 1; }
        let mut best = [0usize; MAX_A];
        let mut best_size = -1i32;
        for code in 0..limit {
            let mut value = code;
            let mut candidate = [0usize; MAX_A];
            let mut used = 0u8;
            let mut size = 0i32;
            let mut valid = true;
            for a in 0..applicants {
                let p = value % (posts + 1);
                value /= posts + 1;
                candidate[a] = p;
                if p == posts { continue; }
                if rank[a][p] == 0 || rank[a][p] as usize > phase || blocked[a][p] || used & (1 << p) != 0 {
                    valid = false;
                    break;
                }
                used |= 1 << p;
                size += 1;
            }
            if valid && (size > best_size || (size == best_size && lex_less(&candidate, &best, applicants))) {
                best_size = size;
                best = candidate;
            }
        }
        mate_a = [-1; MAX_A];
        mate_p = [-1; MAX_P];
        for a in 0..applicants {
            if best[a] < posts {
                mate_a[a] = best[a] as i32;
                mate_p[best[a]] = a as i32;
            }
        }

        let mut classes = [2i8; MAX_V];
        let mut queue = [0usize; MAX_V];
        let (mut head, mut tail) = (0usize, 0usize);
        for a in 0..applicants {
            if mate_a[a] < 0 { classes[a] = 0; queue[tail] = a; tail += 1; }
        }
        for p in 0..posts {
            if mate_p[p] < 0 {
                let v = applicants + p;
                classes[v] = 0;
                queue[tail] = v;
                tail += 1;
            }
        }
        while head < tail {
            let v = queue[head];
            head += 1;
            if v < applicants {
                let a = v;
                if classes[v] == 0 {
                    for p in 0..posts {
                        let w = applicants + p;
                        if rank[a][p] > 0 && rank[a][p] as usize <= phase && !blocked[a][p]
                            && mate_a[a] != p as i32 && classes[w] == 2 {
                            classes[w] = 1; queue[tail] = w; tail += 1;
                        }
                    }
                } else if mate_a[a] >= 0 {
                    let w = applicants + mate_a[a] as usize;
                    if classes[w] == 2 { classes[w] = 0; queue[tail] = w; tail += 1; }
                }
            } else {
                let p = v - applicants;
                if classes[v] == 0 {
                    for a in 0..applicants {
                        if rank[a][p] > 0 && rank[a][p] as usize <= phase && !blocked[a][p]
                            && mate_a[a] != p as i32 && classes[a] == 2 {
                            classes[a] = 1; queue[tail] = a; tail += 1;
                        }
                    }
                } else if mate_p[p] >= 0 {
                    let a = mate_p[p] as usize;
                    if classes[a] == 2 { classes[a] = 0; queue[tail] = a; tail += 1; }
                }
            }
        }
        for a in 0..applicants {
            for p in 0..posts {
                if rank[a][p] == 0 || blocked[a][p] { continue; }
                let (ca, cp) = (classes[a], classes[applicants + p]);
                if rank[a][p] as usize <= phase {
                    if (ca == 1 && cp != 0) || (cp == 1 && ca != 0) { blocked[a][p] = true; }
                } else if ca != 0 || cp != 0 { blocked[a][p] = true; }
            }
        }
    }
    let mut signature = [0i64; MAX_RANK];
    for a in 0..applicants {
        if mate_a[a] >= 0 { signature[rank[a][mate_a[a] as usize] as usize - 1] += 1; }
    }
    let bytes = 8 * (max_rank + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put_i64(&mut staged, 0, max_rank as i64);
    for r in 0..max_rank { put_i64(&mut staged, 8 * (r + 1), signature[r]); }
    core::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
