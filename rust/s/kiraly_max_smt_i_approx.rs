const MAX_M: usize = 6;
const MAX_W: usize = 6;
const MAX_INPUT: usize = 74;
const MAX_OUTPUT: usize = 48;
const MAX_STEPS: usize = 121;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

fn man_prefers(man: usize, a: usize, b: usize, rank: &[[i64; MAX_W]; MAX_M],
               woman_partner: &[i64; MAX_W]) -> bool {
    if rank[man][a] != rank[man][b] { return rank[man][a] < rank[man][b]; }
    let a_maiden = woman_partner[a] == -1;
    let b_maiden = woman_partner[b] == -1;
    if a_maiden != b_maiden { a_maiden } else { a < b }
}

fn uncertain(man: usize, w: usize, rank: &[[i64; MAX_W]; MAX_M], live: &[[bool; MAX_W]; MAX_M],
              assignment: &[i64; MAX_M], woman_partner: &[i64; MAX_W], status: &[u8; MAX_M]) -> bool {
    if status[man] != 0 || assignment[man] < 0 { return false; }
    let fiance = assignment[man] as usize;
    for woman in 0..w {
        if live[man][woman] && woman != fiance &&
            (rank[man][woman] < rank[man][fiance] || (rank[man][woman] == rank[man][fiance] &&
                woman_partner[woman] == -1 && woman_partner[fiance] != -1)) { return true; }
    }
    false
}

fn woman_prefers(woman: usize, candidate: usize, incumbent: usize, incumbent_uncertain: bool,
                 rank: &[[i64; MAX_M]; MAX_W], status: &[u8; MAX_M]) -> bool {
    if incumbent_uncertain { return true; }
    if rank[woman][candidate] != rank[woman][incumbent] { return rank[woman][candidate] < rank[woman][incumbent]; }
    if status[candidate] != status[incumbent] { status[candidate] > status[incumbent] } else { candidate < incumbent }
}

#[no_mangle]
pub unsafe extern "C" fn kiraly_max_smt_i_approx(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let m64 = *input; let w64 = *input.add(1);
    if m64 < 1 || m64 > MAX_M as i64 || w64 < 1 || w64 > MAX_W as i64 { return -1; }
    let m = m64 as usize; let w = w64 as usize;
    if length != 2 + 2*m*w { return -1; }
    let mut men_rank = [[0i64; MAX_W]; MAX_M];
    let mut women_rank = [[0i64; MAX_M]; MAX_W];
    let mut live = [[false; MAX_W]; MAX_M];
    let mut assignment = [-1i64; MAX_M];
    let mut woman_partner = [-1i64; MAX_W];
    let mut status = [0u8; MAX_M]; // 0 lad, 1 bachelor, 2 old bachelor
    for man in 0..m { for woman in 0..w {
        let rank = *input.add(2 + man*w + woman);
        if rank < -1 || rank >= MAX_W as i64 { return -1; }
        men_rank[man][woman] = rank;
    }}
    for woman in 0..w { for man in 0..m {
        let rank = *input.add(2 + m*w + woman*m + man);
        if rank < -1 || rank >= MAX_M as i64 { return -1; }
        women_rank[woman][man] = rank;
    }}
    for man in 0..m { for woman in 0..w {
        let ma = men_rank[man][woman] >= 0; let wa = women_rank[woman][man] >= 0;
        if ma != wa { return -1; }
        live[man][woman] = ma;
    }}
    let output_bytes = 8*m;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut steps = 0usize;
    loop {
        steps += 1;
        if steps > MAX_STEPS { return -1; }
        let mut man = m;
        for x in 0..m { if status[x] != 2 && assignment[x] == -1 { man = x; break; } }
        if man == m { break; }
        let mut woman = w;
        for x in 0..w {
            if live[man][x] && (woman == w || man_prefers(man, x, woman, &men_rank, &woman_partner)) { woman = x; }
        }
        if woman == w {
            if status[man] == 0 {
                status[man] = 1;
                for x in 0..w { live[man][x] = men_rank[man][x] >= 0; }
            } else { status[man] = 2; }
            continue;
        }
        let incumbent64 = woman_partner[woman];
        if incumbent64 < 0 {
            assignment[man] = woman as i64; woman_partner[woman] = man as i64; continue;
        }
        let incumbent = incumbent64 as usize;
        let old_uncertain = uncertain(incumbent, w, &men_rank, &live, &assignment, &woman_partner, &status);
        if woman_prefers(woman, man, incumbent, old_uncertain, &women_rank, &status) {
            assignment[incumbent] = -1; woman_partner[woman] = -1;
            if !old_uncertain { live[incumbent][woman] = false; }
            assignment[man] = woman as i64; woman_partner[woman] = man as i64;
        } else { live[man][woman] = false; }
    }
    let mut staged = [0u8; MAX_OUTPUT];
    for man in 0..m { put64(staged.as_mut_ptr(), 8*man, assignment[man]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
