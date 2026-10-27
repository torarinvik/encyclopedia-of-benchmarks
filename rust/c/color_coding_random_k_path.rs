const N: usize = 12;
const M: usize = 66;
const K: usize = 6;
const T: usize = 8;
const MAX_INPUT: usize = 232;
const MAX_OUTPUT: usize = 64;
fn put(out: &mut [u8], at: usize, value: i64) { out[at..at + 8].copy_from_slice(&value.to_le_bytes()); }
fn less(a: &[i8; K], b: &[i8; K], len: usize) -> bool { for i in 0..len { if a[i] != b[i] { return a[i] < b[i]; } } false }

#[no_mangle]
pub unsafe extern "C" fn color_coding_random_k_path(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let x = std::slice::from_raw_parts(input, length);
    if x[0] < 1 || x[0] > N as i64 || x[1] < 0 || x[1] > M as i64 || x[2] < 1 || x[2] > K as i64 || x[2] > x[0] || x[3] < 1 || x[3] > T as i64 { return -1; }
    let n=x[0] as usize;let m=x[1] as usize;let k=x[2] as usize;let trials=x[3] as usize;let edge_start=4;let color_start=edge_start+2*m;
    if length!=color_start+trials*n{return -1;}
    let mut adj=[0u16;N];
    for e in 0..m { let (a,b)=(x[edge_start+2*e],x[edge_start+2*e+1]);if a<0||b<0||a>=n as i64||b>=n as i64||a==b{return -1;}let(a,b)=(a as usize,b as usize);if adj[a]&(1<<b)!=0{return -1;}adj[a]|=1<<b;adj[b]|=1<<a; }
    for t in 0..trials { for v in 0..n { let c=x[color_start+t*n+v];if c<0||c>=k as i64{return -1;} } }
    let full=(1usize<<k)-1;
    for trial in 0..trials {
        let mut colors=[0usize;N];for v in 0..n{colors[v]=x[color_start+trial*n+v] as usize;}
        let mut reach=[[false;N];1<<K];let mut paths=[[[ -1i8;K];N];1<<K];
        for mask in 0..=full { for v in 0..n { paths[mask][v].fill(-1); } }
        for v in 0..n { let mask=1<<colors[v];reach[mask][v]=true;paths[mask][v][0]=v as i8; }
        for mask in 1..=full { let plen=mask.count_ones() as usize;for v in 0..n { if !reach[mask][v]||mask==full{continue;}for u in 0..n {let cb=1<<colors[u];if adj[v]&(1<<u)==0||mask&cb!=0{continue;}let next=mask|cb;let mut candidate=paths[mask][v];candidate[plen]=u as i8;if !reach[next][u]||less(&candidate,&paths[next][u],plen+1){reach[next][u]=true;paths[next][u]=candidate;}}} }
        let mut best=None;for v in 0..n{if reach[full][v]&&best.map_or(true,|b|less(&paths[full][v],&paths[full][b],k)){best=Some(v);}}
        if let Some(v)=best {let bytes=8*(k+2);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;MAX_OUTPUT];put(&mut staged,0,1);put(&mut staged,8,(trial+1) as i64);for j in 0..k{put(&mut staged,8*(j+2),paths[full][v][j] as i64);}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,bytes);return bytes as i64;}
    }
    if output.is_null()||capacity<16{return -2;}let mut staged=[0u8;16];put(&mut staged,0,0);put(&mut staged,8,0);std::ptr::copy_nonoverlapping(staged.as_ptr(),output,16);16
}
