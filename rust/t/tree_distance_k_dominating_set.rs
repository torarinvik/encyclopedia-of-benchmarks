//! Uncompiled bounded distance-k tree domination draft.
#[no_mangle]
pub unsafe extern "C" fn tree_distance_k_dominating_set(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,length) };
    let (nv,radius)=(values[0],values[1]);
    if !(1..=64).contains(&nv) || !(0..=63).contains(&radius) || length!=nv as usize+1 { return -1; }
    let n=nv as usize;
    let (mut parents,mut depth)=([0usize;64],[0usize;64]);
    let (mut first,mut next)=([None;64],[None;64]);
    for v in 1..n {
        let p=values[1+v];
        if p<0 || p>=v as i64 { return -1; }
        let p=p as usize;
        parents[v]=p; depth[v]=depth[p]+1;
        next[v]=first[p]; first[p]=Some(v);
    }
    let mut covered=[false;64];
    let mut answer=0;
    loop {
        let mut deepest=None;
        for v in 0..n {
            if !covered[v] && deepest.map_or(true,|old| depth[v]>depth[old]) { deepest=Some(v); }
        }
        let Some(mut center)=deepest else { return answer; };
        for _ in 0..radius {
            if center==0 { break; }
            center=parents[center];
        }
        let (mut queue,mut dist)=([0usize;64],[-1i32;64]);
        let (mut head,mut tail)=(0,1);
        queue[0]=center; dist[center]=0;
        while head<tail {
            let v=queue[head]; head+=1; covered[v]=true;
            if i64::from(dist[v])==radius { continue; }
            if v!=0 && dist[parents[v]]<0 {
                let u=parents[v]; dist[u]=dist[v]+1; queue[tail]=u; tail+=1;
            }
            let mut child=first[v];
            while let Some(u)=child {
                if dist[u]<0 { dist[u]=dist[v]+1; queue[tail]=u; tail+=1; }
                child=next[u];
            }
        }
        answer+=1;
    }
}
