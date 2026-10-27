const MAX_N: usize = 3;
const MAX_M: usize = 3;
const MAX_CUTS: usize = 45;

fn popcount(mut value: u64) -> usize {
    let mut count = 0;
    while value != 0 { value &= value - 1; count += 1; }
    count
}
fn shift_cut(cut: u64, n: usize, delay: usize) -> Option<u64> {
    let mut result = 0u64;
    for bit in 0..3*n {
        if cut & (1u64 << bit) != 0 {
            let node = bit / 3;
            let next_delay = bit % 3 + delay;
            if next_delay > 2 { return None; }
            result |= 1u64 << (3*node + next_delay);
        }
    }
    Some(result)
}
fn add_cut(cuts: &mut [[u64; MAX_CUTS]; MAX_N], counts: &mut [usize; MAX_N], node: usize, mask: u64, k: usize) {
    if popcount(mask) > k || cuts[node][..counts[node]].contains(&mask) { return; }
    if counts[node] < MAX_CUTS { cuts[node][counts[node]] = mask; counts[node] += 1; }
}
fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word*8..word*8+8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn sequential_lut_k_cut_enumeration(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=12).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0,k0,m0) = (values[0],values[1],values[2]);
    if !(1..=3).contains(&n0) || !(1..=2).contains(&k0) || !(0..=3).contains(&m0) || length != 3+3*m0 as usize { return -1; }
    let (n,k,m)=(n0 as usize,k0 as usize,m0 as usize);
    let mut edges=[(0usize,0usize,0usize);MAX_M];
    for e in 0..m {
        let (u,v,d)=(values[3+3*e],values[4+3*e],values[5+3*e]);
        if u<0||v<0||u>=v||v>=n as i64||(d!=0&&d!=1) { return -1; }
        let edge=(u as usize,v as usize,d as usize);
        if edges[..e].contains(&edge) { return -1; }
        edges[e]=edge;
    }
    let mut incoming=[[(0usize,0usize);MAX_M];MAX_N];
    let mut degree=[0usize;MAX_N];
    for &(u,v,d) in &edges[..m] { let slot=degree[v]; incoming[v][slot]=(u,d); degree[v]+=1; }
    let mut cuts=[[0u64;MAX_CUTS];MAX_N];
    let mut counts=[0usize;MAX_N];
    for v in 0..n {
        add_cut(&mut cuts,&mut counts,v,1u64<<(3*v),k);
        if degree[v]>0 {
            let c0=counts[incoming[v][0].0];
            let c1=if degree[v]>1 {counts[incoming[v][1].0]} else {1};
            let c2=if degree[v]>2 {counts[incoming[v][2].0]} else {1};
            for a in 0..c0 { for b in 0..c1 { for c in 0..c2 {
                let (u0,d0)=incoming[v][0];
                let mut merged=match shift_cut(cuts[u0][a],n,d0) { Some(mask)=>mask, None=>return -1 };
                if degree[v]>1 { let (u,d)=incoming[v][1]; match shift_cut(cuts[u][b],n,d) {Some(mask)=>merged|=mask,None=>return -1} }
                if degree[v]>2 { let (u,d)=incoming[v][2]; match shift_cut(cuts[u][c],n,d) {Some(mask)=>merged|=mask,None=>return -1} }
                add_cut(&mut cuts,&mut counts,v,merged,k);
            }}}
        }
        cuts[v][..counts[v]].sort_unstable();
    }
    let words=1+(0..n).map(|v|1+counts[v]).sum::<usize>();
    let bytes=words*8;
    if output.is_null()||capacity<bytes { return -2; }
    let out=std::slice::from_raw_parts_mut(output,bytes);
    put_i64(out,0,n as i64); let mut at=1;
    for v in 0..n { put_i64(out,at,counts[v] as i64);at+=1;for &mask in &cuts[v][..counts[v]] {put_i64(out,at,mask as i64);at+=1;} }
    bytes as i64
}
