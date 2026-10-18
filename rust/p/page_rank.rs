const MAX_NODES: usize = 4;
const MAX_INPUT: usize = 19;
const DAMPING: f64 = 0.5;

#[no_mangle]
pub unsafe extern "C" fn page_rank(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(6..=MAX_INPUT).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input,input_length) };
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    if values[0]<2.0 || values[0]>MAX_NODES as f64 || values[0].fract()!=0.0 ||
       values[1]<0.0 || values[1]>8.0 || values[1].fract()!=0.0 { return -1; }
    let nodes=values[0] as usize;let iterations=values[1] as usize;
    if input_length!=2+nodes*nodes { return -1; }
    let mut matrix=[0i64;16];let mut outdegree=[0usize;MAX_NODES];
    for i in 0..nodes*nodes {
        let x=values[2+i];if x!=0.0 && x!=1.0{return -1;}matrix[i]=x as i64;
    }
    for node in 0..nodes {
        if matrix[node*nodes+node]!=0{return -1;}
        for target in 0..nodes {outdegree[node]+=matrix[node*nodes+target] as usize;}
    }
    let mut ranks=[0.0;MAX_NODES];let mut next=[0.0;MAX_NODES];
    for node in 0..nodes {ranks[node]=1.0/nodes as f64;}
    let base_random_jump=(1.0-DAMPING)/nodes as f64;
    for _ in 0..iterations {
        let mut dangling_sum=0.0;
        for node in 0..nodes {if outdegree[node]==0 {dangling_sum+=ranks[node];}}
        let dangling_share=(dangling_sum*DAMPING)/nodes as f64;
        let base_rank=base_random_jump+dangling_share;
        for target in 0..nodes {
            let mut incoming=0.0;
            for source in 0..nodes {if matrix[source*nodes+target]==1 {
                incoming+=ranks[source]/outdegree[source] as f64;
            }}
            next[target]=base_rank+incoming*DAMPING;
        }
        for node in 0..nodes {ranks[node]=next[node];}
    }
    let mut staged=[0.0;MAX_NODES];for node in 0..nodes {staged[node]=ranks[node];}
    if output.is_null()||output_capacity<nodes{return -2;}
    for node in 0..nodes {unsafe{*output.add(node)=staged[node];}}
    nodes as i64
}
