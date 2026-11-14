#[no_mangle]
pub unsafe extern "C" fn highest_label_push_relabel(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=197).contains(&length) { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let (nv,mv,sv,tv)=(values[0],values[1],values[2],values[3]);
    if !(2..=16).contains(&nv) || !(0..=64).contains(&mv) || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv { return -1; }
    let (n,m,source,sink)=(nv as usize,mv as usize,(sv-1) as usize,(tv-1) as usize);
    if length!=4+3*m { return -1; }
    let mut residual=[[0i64;16];16];
    let mut excess=[0i64;16];
    let mut height=[0usize;16];
    for i in 0..m {
        let (u,v,capacity)=(values[4+3*i],values[5+3*i],values[6+3*i]);
        if u<1 || u>nv || v<1 || v>nv || u==v || !(0..=100).contains(&capacity) { return -1; }
        residual[(u-1) as usize][(v-1) as usize]+=capacity;
    }
    height[source]=n;
    for v in 0..n {
        let amount=residual[source][v]; residual[source][v]=0;
        residual[v][source]+=amount; excess[v]+=amount; excess[source]-=amount;
    }
    loop {
        let mut active: Option<usize>=None;
        for v in 0..n {
            if v!=source && v!=sink && excess[v]>0 && active.map_or(true, |u| height[v]>height[u]) { active=Some(v); }
        }
        let u=match active { Some(v)=>v, None=>return excess[sink] };
        let mut destination=None;
        let mut minimum=2*n+1;
        for v in 0..n {
            if residual[u][v]>0 {
                minimum=minimum.min(height[v]);
                if destination.is_none() && height[u]==height[v]+1 { destination=Some(v); }
            }
        }
        match destination {
            Some(v)=>{
                let amount=excess[u].min(residual[u][v]);
                residual[u][v]-=amount; residual[v][u]+=amount; excess[u]-=amount; excess[v]+=amount;
            }
            None=>{
                if minimum>2*n { return -1; }
                height[u]=minimum+1;
            }
        }
    }
}
