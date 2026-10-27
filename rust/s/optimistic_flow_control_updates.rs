const MAX_N: usize = 3;
const MAX_L: usize = 4;
const MAX_INPUT: usize = 20;
const MAX_OUTPUT: usize = 48;
const MAX_UPDATES: usize = 6;
const SCALE: i64 = 46656;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *output.add(position+b) = (bits >> (8*b)) as u8; }
}
fn gcd(mut a: i64, mut b: i64) -> i64 { while b != 0 { let r=a%b; a=b; b=r; } a }

fn update(session: usize, n: usize, links: usize, cap: &[i64; MAX_L],
    path: &[[bool; MAX_L]; MAX_N], rate: &mut [i64; MAX_N]) -> bool {
    let mut best = i64::MAX;
    let mut bottleneck = links;
    for e in 0..links {
        if !path[session][e] { continue; }
        let mut fixed = 0i64;
        let mut active = 1usize;
        for j in 0..n { if j != session && path[j][e] {
            if rate[j] <= rate[session] { fixed += rate[j]; } else { active += 1; }
        }}
        let mut level = rate[session];
        let mut candidate = level;
        for _ in 0..n {
            let numerator = cap[e] * SCALE - fixed;
            if numerator < 0 || numerator % active as i64 != 0 { return false; }
            candidate = numerator / active as i64;
            if candidate < level { return false; }
            let mut next = i64::MAX;
            for j in 0..n { if j != session && path[j][e] && rate[j] > level && rate[j] < next { next = rate[j]; } }
            if next == i64::MAX || candidate <= next { break; }
            let mut saturated = 0usize;
            for j in 0..n { if j != session && path[j][e] && rate[j] == next { saturated += 1; } }
            fixed += saturated as i64 * next;
            active -= saturated;
            level = next;
        }
        if candidate < best { best = candidate; bottleneck = e; }
    }
    if bottleneck == links { return false; }
    rate[session] = best;
    for j in 0..n { if j != session && path[j][bottleneck] && rate[j] > best { rate[j] = best; } }
    true
}

fn choose(mode: usize, step: usize, n: usize, links: usize, cap: &[i64; MAX_L],
    path: &[[bool; MAX_L]; MAX_N], rate: &[i64; MAX_N]) -> usize {
    if mode == 0 { return step % n; }
    if mode == 1 { let mut best=0; for s in 1..n { if rate[s]<rate[best] { best=s; } } return best; }
    if mode == 2 {
        for s in 0..n {
            let mut local = true;
            for j in 0..n { if j != s {
                let mut shares=false; for e in 0..links { if path[s][e] && path[j][e] { shares=true; } }
                if shares && (rate[j]<rate[s] || (rate[j]==rate[s] && j<s)) { local=false; }
            }}
            if local { return s; }
        }
        return 0;
    }
    let mut selected=links; let mut best_load=0i64;
    for e in 0..links {
        let mut load=0i64; let mut used=false;
        for s in 0..n { if path[s][e] { load+=rate[s]; used=true; } }
        if used && (selected==links || load*cap[selected] > best_load*cap[e]) { selected=e; best_load=load; }
    }
    for s in 0..n { if path[s][selected] { return s; } }
    0
}

#[no_mangle]
pub unsafe extern "C" fn optimistic_flow_control_updates(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT { return -1; }
    let n64=*input; let l64=*input.add(1); let mode64=*input.add(2); let q64=*input.add(3);
    if n64<2 || n64>MAX_N as i64 || l64<1 || l64>MAX_L as i64 || mode64<0 || mode64>3 || q64<1 || q64>MAX_UPDATES as i64 { return -1; }
    let n=n64 as usize; let links=l64 as usize; let mode=mode64 as usize; let updates=q64 as usize;
    if length != 4+links+n*links { return -1; }
    let mut cap=[0i64;MAX_L]; let mut path=[[false;MAX_L];MAX_N]; let mut rate=[0i64;MAX_N];
    for e in 0..links { cap[e]=*input.add(4+e); if cap[e]<1||cap[e]>16 { return -1; } }
    for s in 0..n {
        let mut used=false;
        for e in 0..links { let value=*input.add(4+links+s*links+e); if value!=0&&value!=1 { return -1; } path[s][e]=value==1; used|=value==1; }
        if !used { return -1; }
    }
    let bytes=16*n; if output.is_null()||capacity<bytes { return -2; }
    for step in 0..updates { let s=choose(mode,step,n,links,&cap,&path,&rate); if !update(s,n,links,&cap,&path,&mut rate) { return -1; } }
    let mut staged=[0u8;MAX_OUTPUT];
    for s in 0..n { let d=gcd(rate[s],SCALE); put64(staged.as_mut_ptr(),16*s,rate[s]/d); put64(staged.as_mut_ptr(),16*s+8,SCALE/d); }
    for b in 0..bytes { *output.add(b)=staged[b]; }
    bytes as i64
}
