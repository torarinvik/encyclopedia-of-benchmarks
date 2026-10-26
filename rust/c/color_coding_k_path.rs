/// Bounded colorful k-vertex path existence via subset/endpoint dynamic programming.
#[no_mangle]
pub extern "C" fn color_coding_k_path(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() { return -2; }
    if length < 3 || length > 147 { return -1; }
    let x=unsafe{std::slice::from_raw_parts(values,length)};
    let (nv,mv,kv)=(x[0],x[1],x[2]);
    if nv<1||nv>12||mv<0||mv>66||kv<1||kv>6||kv>nv{return -1;}
    let (n,m,k)=(nv as usize,mv as usize,kv as usize);let split=3+n;
    if length!=split+2*m{return -1;}
    let mut colors=[0usize;12];let mut adj=[0u16;12];
    for v in 0..n { if x[3+v]<0||x[3+v]>=kv{return -1;} colors[v]=x[3+v] as usize; }
    for e in 0..m {let (a,b)=(x[split+2*e],x[split+2*e+1]);if a<0||b<0||a>=nv||b>=nv||a==b{return -1;}
        let (a,b)=(a as usize,b as usize);if adj[a]&(1<<b)!=0{return -1;}adj[a]|=1<<b;adj[b]|=1<<a;}
    let mut dp=[[false;12];64];for v in 0..n{dp[1<<colors[v]][v]=true;}
    let full=(1usize<<k)-1;let mut found=false;
    for mask in 1..=full {for v in 0..n {if !dp[mask][v]{continue;}if mask==full{found=true;break;}
        for u in 0..n {let bit=1<<colors[u];if adj[v]&(1<<u)!=0&&mask&bit==0{dp[mask|bit][u]=true;}}}if found{break;}}
    if output_capacity<8||output.is_null(){return -2;}let bytes=unsafe{std::slice::from_raw_parts_mut(output,8)};bytes.fill(0);bytes[0]=found as u8;8
}
