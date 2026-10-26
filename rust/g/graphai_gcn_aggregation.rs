#[no_mangle]
pub unsafe extern "C" fn graphai_gcn_aggregation(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    const N:usize=8;const M:usize=24;const D:usize=4;const MAX_INPUT:usize=4+3*N+M+N*D;
    if input.is_null()||length<7||length>MAX_INPUT{return -1;}
    for q in 0..length{let x=*input.add(q);if !x.is_finite(){return -1;}}
    let nv=*input;let mv=*input.add(1);let dv=*input.add(2);
    if nv.fract()!=0.0||mv.fract()!=0.0||dv.fract()!=0.0||nv<1.0||nv>N as f64||mv<0.0||mv>M as f64||dv<1.0||dv>D as f64{return -1;}
    let n=nv as usize;let m=mv as usize;let d=dv as usize;if length!=4+3*n+m+n*d{return -1;}
    let oa=3;let ea=oa+n+1;let la=ea+m;let ra=la+n;let fa=ra+n;
    if *input.add(oa)!=0.0||*input.add(ea-1)!=m as f64{return -1;}
    let mut rowptr=[0usize;N+1];let mut colind=[0usize;M];
    for i in 0..=n{let x=*input.add(oa+i);if x.fract()!=0.0||x<0.0||x>m as f64{return -1;}rowptr[i]=x as usize;if i>0&&rowptr[i]<rowptr[i-1]{return -1;}}
    for e in 0..m{let x=*input.add(ea+e);if x.fract()!=0.0||x<0.0||x>=n as f64{return -1;}colind[e]=x as usize;}
    for i in 0..n{let a=*input.add(la+i);let b=*input.add(ra+i);if !(-4.0..=4.0).contains(&a)||!(-4.0..=4.0).contains(&b){return -1;}}
    for q in 0..n*d{let x=*input.add(fa+q);if !(-8.0..=8.0).contains(&x){return -1;}}
    let required=n*d;if output.is_null()||capacity<required{return -2;}
    let mut staged=[0.0f64;N*D];
    for src in 0..n{for e in rowptr[src]..rowptr[src+1]{let dst=colind[e];let w=*input.add(la+src) * *input.add(ra+dst);for k in 0..d{let at=src*d+k;staged[at]+=w * *input.add(fa+dst*d+k);}}}
    for q in 0..required{*output.add(q)=staged[q];}required as i64
}
