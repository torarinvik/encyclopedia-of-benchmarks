// Clean-room bounded Kanj--Perkovic modified-Yao selection pass.
const N: usize = 16;
const M: usize = 42;
const K: usize = 14;
const D: usize = 84;
const VALID: usize = 312;
const PARSEABLE: usize = 313;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > PARSEABLE { return -1; }
    let (n64, m64) = (input[0], input[1]);
    if !(3..=N as i64).contains(&n64) || m64 < n64 - 1 || m64 > M as i64 ||
        m64 > 3 * n64 - 6 || input.len() != 2 + n64 as usize + 7 * m64 as usize || input.len() > VALID { return -1; }
    let (n, m, dcount) = (n64 as usize, m64 as usize, 2 * m64 as usize);
    let mut eu = [0usize; M]; let mut ev = [0usize; M];
    let mut cu = [0usize; M]; let mut cv = [0usize; M];
    let mut weight = [0i64; M]; let mut adjacent = [[false; N]; N];
    let mut expected_degree = [0usize; N]; let mut source = [0usize; D]; let mut cone = [0usize; D];
    for e in 0..m {
        let p = 2 + 5 * e;
        let (u, v, w, a, b) = (input[p], input[p+1], input[p+2], input[p+3], input[p+4]);
        if u < 0 || u >= v || v >= n64 || !(1..=1_000_000_000_000).contains(&w) || !(0..K as i64).contains(&a) || !(0..K as i64).contains(&b) { return -1; }
        if e > 0 && ((u as usize) < eu[e-1] || ((u as usize) == eu[e-1] && (v as usize) <= ev[e-1])) { return -1; }
        let (u, v) = (u as usize, v as usize);
        eu[e]=u; ev[e]=v; weight[e]=w; cu[e]=a as usize; cv[e]=b as usize;
        adjacent[u][v]=true; adjacent[v][u]=true; expected_degree[u]+=1; expected_degree[v]+=1;
        source[2*e]=u; source[2*e+1]=v; cone[2*e]=a as usize; cone[2*e+1]=b as usize;
    }
    let mut rotation=[0usize; D]; let mut position=[0usize; D];
    let mut row_start=[0usize; N]; let mut degree=[0usize; N];
    let mut first=[[-1i16; K]; N]; let mut after=[[-1i16; K]; N]; let mut seen=[false; D];
    let mut cursor=2+5*m; let mut used=0usize;
    for v in 0..n {
        let d=input[cursor]; cursor+=1;
        if d < 1 || (d as usize) != expected_degree[v] || (d as usize) > D { return -1; }
        row_start[v]=used; degree[v]=d as usize; let mut previous=-1i64;
        for _ in 0..d as usize {
            let raw=input[cursor]; cursor+=1;
            if raw < 0 || (raw as usize) >= dcount { return -1; }
            let dart=raw as usize; let c=cone[dart];
            if seen[dart] || source[dart] != v || (c as i64) < previous { return -1; }
            previous=c as i64; seen[dart]=true; rotation[used]=dart; position[dart]=used;
            if first[v][c] < 0 { first[v][c]=used as i16; }
            after[v][c]=(used+1) as i16; used+=1;
        }
    }
    if cursor != input.len() || used != dcount || seen[..dcount].iter().any(|x| !x) { return -1; }
    let mut reached=[false; N]; let mut queue=[0usize; N]; let (mut head,mut tail)=(0usize,0usize);
    queue[tail]=0; tail+=1; reached[0]=true;
    while head<tail { let u=queue[head]; head+=1; for v in 0..n { if adjacent[u][v]&&!reached[v] { reached[v]=true; queue[tail]=v; tail+=1; } } }
    if tail!=n { return -1; }
    let mut next_face=[0usize; D]; let mut visited=[false; D]; let mut faces=0i64;
    for d in 0..dcount { let twin=d^1; let dest=source[twin]; let local=position[twin]-row_start[dest]; next_face[d]=rotation[row_start[dest]+(local+degree[dest]-1)%degree[dest]]; }
    for d in 0..dcount { if !visited[d] { faces+=1; let mut x=d; while !visited[x] { visited[x]=true; x=next_face[x]; } if x!=d { return -1; } } }
    if n as i64-m as i64+faces!=2 { return -1; }
    let mut selected=[false; D];
    for v in 0..n { for c in 0..K { if first[v][c]<0 {continue;} let (lo,hi)=(first[v][c] as usize,after[v][c] as usize); let mut best=usize::MAX;
        for p in lo..hi { let d=rotation[p]; let e=d/2; if best==usize::MAX || weight[e]<weight[best/2] || (weight[e]==weight[best/2]&&e<best/2) {best=d;} }
        selected[best]=true;
    } }
    for v in 0..n { if first[v].iter().all(|&x| x<0) {continue;} for start in 0..K {
        if first[v][start]>=0 || first[v][(start+K-1)%K]<0 {continue;}
        let mut len=0usize; while len<K&&first[v][(start+len)%K]<0 {len+=1;}
        if len==1 { let cw_c=(start+K-1)%K; let ccw_c=(start+1)%K; let cw=rotation[after[v][cw_c] as usize-1]; let ccw=rotation[first[v][ccw_c] as usize];
            if selected[cw] {selected[ccw]=true;} else if selected[ccw] {selected[cw]=true;} else {let a=cw/2;let b=ccw/2;selected[if weight[a]<weight[b]||(weight[a]==weight[b]&&a<b){cw}else{ccw}]=true;}
        } else { let (mut cw_left,mut ccw_left)=(len/2,(len+1)/2);
            for step in 1..=K {if cw_left==0 {break;} let c=(start+K-step)%K; if first[v][c]>=0 {for p in (first[v][c] as usize..after[v][c] as usize).rev(){if !selected[rotation[p]]{selected[rotation[p]]=true;cw_left-=1;if cw_left==0{break;}}}}}
            for step in len..len+K {if ccw_left==0 {break;} let c=(start+step)%K; if first[v][c]>=0 {for p in first[v][c] as usize..after[v][c] as usize {if !selected[rotation[p]]{selected[rotation[p]]=true;ccw_left-=1;if ccw_left==0{break;}}}}}
        }
    } }
    let mut mask=0u64; for e in 0..m {if selected[2*e]&&selected[2*e+1]{mask|=1u64<<e;}}
    mask as i64
}

#[no_mangle]
pub unsafe extern "C" fn kanj_perkovic_modified_yao_spanner(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length > PARSEABLE { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
