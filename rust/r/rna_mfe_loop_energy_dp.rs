const MAX_N: usize = 12;
const MAX_PAIRS: usize = 36;
const TABLE_VALUES: usize = 234;
const MAX_INPUT: usize = 247;
const MAX_OUTPUT: usize = 112;
const INF: i64 = 1_i64 << 60;

fn pair_type(left: i64, right: i64) -> i32 {
    match (left, right) { (0, 3) => 0, (3, 0) => 1, (1, 2) => 2, (2, 1) => 3, (2, 3) => 4, (3, 2) => 5, _ => -1 }
}
fn lex_less_mask(left: u64, right: u64, count: usize) -> bool {
    let mut li = 0; let mut ri = 0;
    loop {
        while li < count && ((left >> li) & 1) == 0 { li += 1; }
        while ri < count && ((right >> ri) & 1) == 0 { ri += 1; }
        if li == count || ri == count { return li == count && ri < count; }
        if li != ri { return li < ri; }
        li += 1; ri += 1;
    }
}
fn loop_cost(input: *const i64, n: usize, kind: i32, unpaired: usize, children: usize) -> i64 {
    *input.add(1 + n + kind as usize * 39 + unpaired * 3 + children)
}
unsafe fn put64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64; for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn rna_mfe_loop_energy_dp(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 239 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 4 || n64 > MAX_N as i64 || length != 1 + n64 as usize + TABLE_VALUES { return -1; }
    let n = n64 as usize;
    let mut bases = [0_i64; MAX_N];
    for i in 0..n { bases[i] = *input.add(1 + i); if bases[i] < 0 || bases[i] > 3 { return -1; } }
    for i in 1 + n..length { let cost = *input.add(i); if cost < -1000 || cost > 1000 { return -1; } }
    let mut types = [[-1_i32; MAX_N]; MAX_N]; let mut ids = [[-1_i32; MAX_N]; MAX_N];
    let mut pair_i = [0_i32; MAX_PAIRS]; let mut pair_j = [0_i32; MAX_PAIRS]; let mut pair_count = 0;
    for i in 0..n { for j in i + 4..n { let kind = pair_type(bases[i], bases[j]); if kind >= 0 { types[i][j] = kind; ids[i][j] = pair_count as i32; pair_i[pair_count] = i as i32; pair_j[pair_count] = j as i32; pair_count += 1; } } }
    let mut ve = [[INF; MAX_N]; MAX_N]; let mut vm = [[0_u64; MAX_N]; MAX_N];
    for span in 4..n { for i in 0..n - span { let j = i + span; let kind = types[i][j]; if kind < 0 { continue; }
        let outer = 1_u64 << ids[i][j] as u32; let mut best = INF; let mut best_mask = 0_u64;
        let mut candidate = loop_cost(input,n,kind,span-1,0); if candidate < best || (candidate == best && lex_less_mask(outer,best_mask,pair_count)) { best=candidate; best_mask=outer; }
        for a in i+1..j { for b in a+4..j { if ids[a][b]<0 || ve[a][b]==INF {continue;} let u=a-i-1+j-b-1; candidate=loop_cost(input,n,kind,u,1)+ve[a][b]; let mask=outer|vm[a][b]; if candidate<best || (candidate==best&&lex_less_mask(mask,best_mask,pair_count)){best=candidate;best_mask=mask;} } }
        for a in i+1..j { for b in a+4..j { if ids[a][b]<0 || ve[a][b]==INF {continue;} for c in b+1..j { for d in c+4..j { if ids[c][d]<0 || ve[c][d]==INF {continue;} let u=a-i-1+c-b-1+j-d-1; candidate=loop_cost(input,n,kind,u,2)+ve[a][b]+ve[c][d]; let mask=outer|vm[a][b]|vm[c][d]; if candidate<best || (candidate==best&&lex_less_mask(mask,best_mask,pair_count)){best=candidate;best_mask=mask;} } } } }
        ve[i][j]=best; vm[i][j]=best_mask;
    } }
    let mut we=[0_i64;MAX_N]; let mut wm=[0_u64;MAX_N];
    for j in 0..n { let mut best=if j==0{0}else{we[j-1]}; let mut best_mask=if j==0{0}else{wm[j-1]};
        for i in 0..=j.saturating_sub(4) { if j-i<4 || types[i][j]<0 || ve[i][j]==INF {continue;} let prefix=if i==0{0}else{we[i-1]}; let mask=(if i==0{0}else{wm[i-1]})|vm[i][j]; let value=prefix+ve[i][j]; if value<best || (value==best&&lex_less_mask(mask,best_mask,pair_count)){best=value;best_mask=mask;} }
        we[j]=best;wm[j]=best_mask;
    }
    let mut count=0_i64; for p in 0..pair_count {if (wm[n-1]>>p)&1!=0{count+=1;}}
    let bytes=8*(2+2*count as usize);if output.is_null()||capacity<bytes{return -2;}
    let mut staged=[0_u8;MAX_OUTPUT];put64(staged.as_mut_ptr(),0,we[n-1]);put64(staged.as_mut_ptr(),8,count);let mut at=2;
    for p in 0..pair_count {if (wm[n-1]>>p)&1!=0{put64(staged.as_mut_ptr(),8*at,pair_i[p] as i64);at+=1;put64(staged.as_mut_ptr(),8*at,pair_j[p] as i64);at+=1;}}
    for b in 0..bytes{*output.add(b)=staged[b];}bytes as i64
}
