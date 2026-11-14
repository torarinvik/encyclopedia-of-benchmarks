fn send(u: usize, sink: usize, amount: i64, residual: &mut [[i64; 16]; 16],
        level: &[i32; 16], cursor: &mut [usize; 16], n: usize, threshold: i64) -> i64 {
    if u == sink { return amount; }
    while cursor[u] < n {
        let v = cursor[u];
        if level[v] == level[u]+1 && residual[u][v] >= threshold {
            let bound = amount.min(residual[u][v]);
            let pushed = send(v, sink, bound, residual, level, cursor, n, threshold);
            if pushed > 0 { residual[u][v] -= pushed; residual[v][u] += pushed; return pushed; }
        }
        cursor[u] += 1;
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn dinic_capacity_scaling(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=197).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (nv,mv,sv,tv) = (values[0],values[1],values[2],values[3]);
    if !(2..=16).contains(&nv) || !(0..=64).contains(&mv) || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv { return -1; }
    let (n,m,source,sink) = (nv as usize,mv as usize,(sv-1) as usize,(tv-1) as usize);
    if length != 4+3*m { return -1; }
    let mut residual = [[0i64; 16]; 16];
    for i in 0..m {
        let (u,v,capacity) = (values[4+3*i],values[5+3*i],values[6+3*i]);
        if u<1 || u>nv || v<1 || v>nv || u==v || !(0..=100).contains(&capacity) { return -1; }
        residual[(u-1) as usize][(v-1) as usize] += capacity;
    }
    let greatest = residual.iter().flatten().copied().max().unwrap_or(0);
    let (mut threshold,mut flow) = (1i64,0i64);
    while threshold <= greatest/2 { threshold *= 2; }
    if greatest == 0 { threshold = 0; }
    while threshold > 0 {
        loop {
            let mut level = [-1i32; 16];
            let mut queue = [0usize; 16];
            let (mut head,mut tail) = (0,1);
            level[source]=0; queue[0]=source;
            while head<tail {
                let u=queue[head]; head+=1;
                for v in 0..n {
                    if level[v]<0 && residual[u][v]>=threshold {
                        level[v]=level[u]+1; queue[tail]=v; tail+=1;
                    }
                }
            }
            if level[sink]<0 { break; }
            let mut cursor=[0usize; 16];
            loop {
                let pushed=send(source,sink,6401,&mut residual,&level,&mut cursor,n,threshold);
                if pushed==0 { break; }
                flow+=pushed;
            }
        }
        threshold/=2;
    }
    flow
}
