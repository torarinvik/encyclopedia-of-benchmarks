#[no_mangle]
pub unsafe extern "C" fn viterbi(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > 64 { return -1; }
    let obs = std::slice::from_raw_parts(input, length);
    if obs.iter().any(|&x| !(0..=2).contains(&x)) { return -1; }
    if output.is_null() || capacity < length * 8 { return -2; }
    let start = [0.6f64, 0.4]; let tr = [[0.7f64,0.3],[0.4,0.6]];
    let em = [[0.5f64,0.4,0.1],[0.1,0.3,0.6]];
    let mut score = [start[0]*em[0][obs[0] as usize], start[1]*em[1][obs[0] as usize]];
    let mut back = [[0usize;2];64];
    for t in 1..length { let mut next=[0.0;2]; for s in 0..2 { let a=score[0]*tr[0][s]*em[s][obs[t] as usize]; let b=score[1]*tr[1][s]*em[s][obs[t] as usize]; let p=if b>a {1} else {0}; back[t][s]=p; next[s]=if p==0 {a} else {b}; } score=next; }
    let mut state=if score[1]>score[0] {1} else {0}; let mut path=[0i64;64]; path[length-1]=state as i64;
    for t in (1..length).rev() { state=back[t][state]; path[t-1]=state as i64; }
    let out=std::slice::from_raw_parts_mut(output,length*8);
    for i in 0..length { out[i*8..i*8+8].copy_from_slice(&path[i].to_le_bytes()); }
    (length*8) as i64
}
