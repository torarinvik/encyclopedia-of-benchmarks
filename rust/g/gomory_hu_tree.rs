fn maxflow(cap: &[i64; 64], n: usize, source: usize, sink: usize) -> (i64, [bool; 8]) {
    let mut residual = *cap;
    let mut total = 0;
    loop {
        let mut parent = [-1i32; 8]; parent[source] = source as i32;
        let mut queue = [0usize; 8]; let (mut head, mut tail) = (0, 1); queue[0] = source;
        while head < tail && parent[sink] < 0 {
            let u = queue[head]; head += 1;
            for v in 0..n { if residual[u*n+v] > 0 && parent[v] < 0 { parent[v] = u as i32; if v == sink { break; } queue[tail] = v; tail += 1; } }
        }
        if parent[sink] < 0 { break; }
        let mut amount = i64::MAX; let mut v = sink;
        while v != source { let u = parent[v] as usize; amount = amount.min(residual[u*n+v]); v = u; }
        v = sink; while v != source { let u = parent[v] as usize; residual[u*n+v] -= amount; residual[v*n+u] += amount; v = u; }
        total += amount;
    }
    let mut reachable = [false; 8]; let mut queue = [0usize; 8]; let (mut head, mut tail) = (0, 1); queue[0] = source; reachable[source] = true;
    while head < tail { let u = queue[head]; head += 1; for v in 0..n { if !reachable[v] && residual[u*n+v] > 0 { reachable[v] = true; queue[tail] = v; tail += 1; } } }
    (total, reachable)
}

#[no_mangle]
pub unsafe extern "C" fn gomory_hu_tree(a: *const i64, length: usize) -> i64 {
    if a.is_null() || length < 2 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(a, length); let n = values[0];
    if !(1..=8).contains(&n) || length != 1 + (n*n) as usize { return -1; }
    let n = n as usize; let mut cap = [0i64; 64];
    for i in 0..n*n { let x=values[1+i]; if !(0..=1000).contains(&x) { return -1; } cap[i]=x; }
    for i in 0..n { for j in 0..n { if cap[i*n+j] != if i==j {0} else {cap[j*n+i]} { return -1; } } }
    let mut parent=[0usize;8]; let mut weight=[0i64;8];
    for s in 1..n { let t=parent[s]; let (f,reach)=maxflow(&cap,n,s,t); weight[s]=f;
        for v in 0..n { if v!=s && parent[v]==t && reach[v] {parent[v]=s;} }
        if t!=0 && reach[parent[t]] {parent[s]=parent[t];parent[t]=s;weight[s]=weight[t];weight[t]=f;}
    }
    let mut pair=[0i64;64];
    for source in 0..n {let mut prev=[-2i32;8];let mut q=[0usize;8];let(mut head,mut tail)=(0,1);q[0]=source;prev[source]=-1;
        while head<tail {let u=q[head];head+=1;for v in 0..n {if v!=u && ((v>0&&parent[v]==u)||(u>0&&parent[u]==v)) && prev[v]==-2 {prev[v]=u as i32;q[tail]=v;tail+=1;}}}
        for target in 0..n {if target!=source {let mut x=target;let mut m=i64::MAX;while x!=source {let p=prev[x] as usize;let edge=if x>0&&parent[x]==p{x}else{p};m=m.min(weight[edge]);x=p;}pair[source*n+target]=m;}}
    }
    let mut h=14695981039346656037u64;for value in &pair[..n*n] {let mut bits=*value as u64;for _ in 0..8 {h=(h^(bits&255)).wrapping_mul(1099511628211);bits>>=8;}}
    h as i64
}
