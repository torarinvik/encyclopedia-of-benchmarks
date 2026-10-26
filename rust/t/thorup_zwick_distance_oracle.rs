const N: usize = 12;
const M: usize = 66;
const Q: usize = 32;
const INF: i64 = i64::MAX / 4;

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn thorup_zwick_distance_oracle(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 266 { return -1; }
    let n0=*input; let m0=*input.add(1); let mask0=*input.add(2);
    if n0<1||n0>N as i64||m0<0||m0>M as i64||mask0<=0{return -1;}
    let n=n0 as usize; let m=m0 as usize; let mask=mask0 as u64;
    if mask >> n != 0 { return -1; }
    let q_at=3+3*m;
    if q_at>=length { return -1; }
    let q0=*input.add(q_at);
    if q0<0||q0>Q as i64 { return -1; }
    let q=q0 as usize;
    if length!=q_at+1+2*q { return -1; }
    let mut d=[[INF;N];N];
    for i in 0..n { d[i][i]=0; }
    for e in 0..m {
        let u=*input.add(3+3*e);let v=*input.add(4+3*e);let w=*input.add(5+3*e);
        if u<0||v<=u||v>=n as i64||w<1||w>1000{return -1;}
        let (u,v)=(u as usize,v as usize);if d[u][v]!=INF{return -1;}d[u][v]=w;d[v][u]=w;
    }
    for k in 0..n { for i in 0..n { for j in 0..n {
        if d[i][k]!=INF&&d[k][j]!=INF { let x=d[i][k]+d[k][j];if x<d[i][j]{d[i][j]=x;} }
    }}}
    for i in 0..n { for j in 0..n { if d[i][j]==INF{return -1;} }}
    let mut nearest=[0usize;N];let mut near_d=[INF;N];
    for v in 0..n { let mut found=false;for a in 0..n {if mask>>a&1!=0 && (!found||d[v][a]<near_d[v]||(d[v][a]==near_d[v]&&a<nearest[v])){nearest[v]=a;near_d[v]=d[v][a];found=true;}} }
    let mut bunch=[[false;N];N];
    for u in 0..n { for x in 0..n { bunch[u][x]=(mask>>x&1)!=0||d[u][x]<near_d[u]; }}
    let mut staged=[0i64;Q+1];staged[0]=q as i64;
    for z in 0..q {let a=*input.add(q_at+1+2*z);let b=*input.add(q_at+2+2*z);if a<0||a>=n as i64||b<0||b>=n as i64{return -1;}
        let(mut u,mut v)=(a as usize,b as usize);let mut found=false;
        for level in 0..2 {let pivot=if level==0{v}else{nearest[v]};if bunch[u][pivot]{staged[z+1]=d[u][pivot]+d[v][pivot];found=true;break;}std::mem::swap(&mut u,&mut v);}
        if !found{return -1;}
    }
    let bytes=8*(q+1);if output.is_null()||capacity<bytes{return -2;}
    for i in 0..q+1 {write_i64_le(output,8*i,staged[i]);}
    bytes as i64
}
