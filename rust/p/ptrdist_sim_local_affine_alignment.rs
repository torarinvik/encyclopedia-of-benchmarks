/// Clean-room port of SIM's documented first-best local affine score.
#[no_mangle]
pub extern "C" fn ptrdist_sim_local_affine_alignment(input: *const i64, length: usize) -> i64 {
    const STRIDE: usize = 65;
    if input.is_null() || !(4..=130).contains(&length) { return -1; }
    let x = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&x[0]) { return -1; }
    let left = x[0] as usize;
    let right_pos = 1 + left;
    if right_pos >= length || !(1..=64).contains(&x[right_pos]) { return -1; }
    let right = x[right_pos] as usize;
    if length != right_pos + 1 + right { return -1; }
    let dna = |c: i64| matches!(c, 65 | 67 | 71 | 84);
    if !x[1..right_pos].iter().copied().all(dna) ||
       !x[right_pos+1..].iter().copied().all(dna) { return -1; }
    let mut h = [0i64; STRIDE * STRIDE];
    let mut d = [0i64; STRIDE * STRIDE];
    let mut f = [0i64; STRIDE * STRIDE];
    for j in 1..=right { d[j] = -60; }
    for i in 1..=left { f[i * STRIDE] = -60; }
    let mut best = 0;
    for i in 1..=left { for j in 1..=right {
        let p = i * STRIDE + j;
        d[p] = (h[p-STRIDE]-62).max(d[p-STRIDE]-2);
        f[p] = (h[p-1]-62).max(f[p-1]-2);
        let mut score = h[p-STRIDE-1] + if x[i] == x[right_pos+j] { 10 } else { -10 };
        score = score.max(0).max(d[p]).max(f[p]);
        h[p] = score;
        best = best.max(score);
    }}
    best
}
