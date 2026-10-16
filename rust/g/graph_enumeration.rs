#[no_mangle]
pub extern "C" fn graph_enumeration(a: *const i64, length: usize) -> i64 {
    if a.is_null() || length < 1 { return -1; }
    let x=unsafe{std::slice::from_raw_parts(a,length)}; let n=x[0];
    if !(0..=16).contains(&n)||length<1+n as usize{return -1;} let n=n as usize;
    let labels=&x[1..1+n]; if labels.iter().any(|v| !(-1_000_000..=1_000_000).contains(v)){return -1;}
    for i in 0..n {if labels[..i].contains(&labels[i]){return -1;}}
    let mut ordered=labels.to_vec();ordered.sort();let mut adjacency=vec![Vec::<i64>::new();n];let mut off=1+n;
    for i in 0..n {if off>=length{return -1;}let d=x[off];off+=1;if !(0..=32).contains(&d)||off+d as usize>length{return -1;}for &v in &x[off..off+d as usize]{if !labels.contains(&v){return -1;}}adjacency[i]=x[off..off+d as usize].to_vec();off+=d as usize;}
    if off!=length{return -1;}
    let mut h:u64=14695981039346656037; let mut mix=|v:i64|{let mut z=v as u64;for _ in 0..8{h=(h^(z&255)).wrapping_mul(1099511628211);z>>=8;}};
    mix((n+1) as i64);mix(0);
    for label in ordered {let i=labels.iter().position(|&v|v==label).unwrap();mix(adjacency[i].len() as i64);for v in &adjacency[i]{let k=ordered_index(labels,*v);mix((k+1) as i64);}}
    h as i64
}
fn ordered_index(labels:&[i64], v:i64)->usize {let mut k=0;while k<labels.len(){if labels[k]==v{break;}k+=1;}let mut rank=0;for &x in labels{if x<v{rank+=1;}}rank}
