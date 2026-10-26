#[no_mangle]
pub unsafe extern "C" fn graphai_sage_aggregation(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    const N:usize=8;const M:usize=24;const D:usize=4;const MAX_INPUT:usize=4+N+M+N*D;
    if input.is_null()||length<4||length>MAX_INPUT{return -1;}for q in 0..length{if !(*input.add(q)).is_finite(){return -1;}}
    let nv=*input;let mv=*input.add(1);let dv=*input.add(2);if nv.fract()!=0.0||mv.fract()!=0.0||dv.fract()!=0.0||nv<1.0||nv>N as f64||mv<0.0||mv>M as f64||dv<1.0||dv>D as f64{return -1;}
    let n=nv as usize;let m=mv as usize;let d=dv as usize;if length!=4+n+m+n*d{return -1;}let rp=3;let ci=rp+n+1;let xf=ci+m;
    if *input.add(rp)!=0.0||*input.add(ci-1)!=m as f64{return -1;}let mut rows=[0usize;N+1];let mut cols=[0usize;M];
    for i in 0..=n{let x=*input.add(rp+i);if x.fract()!=0.0||x<0.0||x>m as f64{return -1;}rows[i]=x as usize;if i>0&&rows[i]<rows[i-1]{return -1;}}
    for e in 0..m{let x=*input.add(ci+e);if x.fract()!=0.0||x<0.0||x>=n as f64{return -1;}cols[e]=x as usize;}
    for q in 0..n*d{let x=*input.add(xf+q);if !(-8.0..=8.0).contains(&x){return -1;}}
    let required=n*d;if output.is_null()||capacity<required{return -2;}let mut staged=[0.0f64;N*D];
    for src in 0..n{let degree=rows[src+1]-rows[src];if degree>0{let scale=1.0/(degree as f64);for e in rows[src]..rows[src+1]{let dst=cols[e];for k in 0..d{staged[src*d+k]+=scale * *input.add(xf+dst*d+k);}}}}
    for q in 0..required{*output.add(q)=staged[q];}required as i64
}
