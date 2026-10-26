#[no_mangle]
pub unsafe extern "C" fn graphai_cf_sgd_sweep(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    const N:usize=8;const M:usize=24;const K:usize=4;const MAX_INPUT:usize=7+N+2*M+N*K;
    if input.is_null()||length<6||length>MAX_INPUT{return -1;}for q in 0..length{if !(*input.add(q)).is_finite(){return -1;}}
    let uv=*input;let iv=*input.add(1);let mv=*input.add(2);let kv=*input.add(3);
    if uv.fract()!=0.0||iv.fract()!=0.0||mv.fract()!=0.0||kv.fract()!=0.0||uv<1.0||uv>7.0||iv<1.0||iv>7.0||mv<0.0||mv>M as f64||kv<1.0||kv>K as f64{return -1;}
    let users=uv as usize;let items=iv as usize;let n=users+items;let m=mv as usize;let k=kv as usize;let lambda=*input.add(4);let step=*input.add(5);
    if n>N||lambda<0.0||lambda>1.0||step<0.0||step>0.01||length!=7+n+2*m+n*k{return -1;}
    let rp=6;let ci=rp+n+1;let ra=ci+m;let la=ra+m;if *input.add(rp)!=0.0||*input.add(ci-1)!=m as f64{return -1;}
    let mut rows=[0usize;N+1];let mut cols=[0usize;M];for i in 0..=n{let x=*input.add(rp+i);if x.fract()!=0.0||x<0.0||x>m as f64{return -1;}rows[i]=x as usize;if i>0&&rows[i]<rows[i-1]{return -1;}}
    for u in users..n{if rows[u]!=rows[u+1]{return -1;}}
    for e in 0..m{let x=*input.add(ci+e);if x.fract()!=0.0||x<users as f64||x>=n as f64{return -1;}cols[e]=x as usize;}
    for e in 0..m{let x=*input.add(ra+e);if !(-4.0..=4.0).contains(&x){return -1;}}
    for q in 0..n*k{let x=*input.add(la+q);if !(-2.0..=2.0).contains(&x){return -1;}}
    let required=n*k;if output.is_null()||capacity<required{return -2;}let mut error=[0.0f64;N*K];let mut staged=[0.0f64;N*K];
    for u in 0..users{for e in rows[u]..rows[u+1]{let v=cols[e];let mut estimate=0.0;for j in 0..k{estimate+=*input.add(la+u*k+j) * *input.add(la+v*k+j);}let delta=*input.add(ra+e)-estimate;for j in 0..k{error[u*k+j]+=*input.add(la+v*k+j)*delta;}}}
    for v in 0..n{for j in 0..k{let q=v*k+j;staged[q]=*input.add(la+q)+step*(-lambda * *input.add(la+q)+error[q]);}}
    for q in 0..required{*output.add(q)=staged[q];}required as i64
}
