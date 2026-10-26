import math
@[export: 'graphai_cf_sgd_sweep']
pub fn graphai_cf_sgd_sweep(input &f64,length usize,mut output &f64,capacity usize)i64 {
    unsafe {
        if input==nil||length<6||length>95{return -1};for q in 0..length{if !input[q].is_finite(){return -1}}
        uv,iv,mv,kv:=input[0],input[1],input[2],input[3]
        if math.trunc(uv)!=uv||math.trunc(iv)!=iv||math.trunc(mv)!=mv||math.trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<0||mv>24||kv<1||kv>4{return -1}
        users,items,m,k:=int(uv),int(iv),int(mv),int(kv);n:=users+items;lambda,step:=input[4],input[5]
        if n>8||lambda<0||lambda>1||step<0||step>0.01||length!=usize(7+n+2*m+n*k){return -1}
        rp:=6;ci:=rp+n+1;ra:=ci+m;la:=ra+m
        if input[rp]!=0||input[ci-1]!=f64(m){return -1};mut rows:=[9]int{};mut cols:=[24]int{}
        for i in 0..n+1{x:=input[rp+i];if math.trunc(x)!=x||x<0||x>f64(m){return -1};rows[i]=int(x);if i>0&&rows[i]<rows[i-1]{return -1}}
        for u in users..n{if rows[u]!=rows[u+1]{return -1}}
        for e in 0..m{x:=input[ci+e];if math.trunc(x)!=x||x<f64(users)||x>=f64(n){return -1};cols[e]=int(x)}
        for e in 0..m{if input[ra+e]<-4||input[ra+e]>4{return -1}}
        for q in 0..n*k{if input[la+q]<-2||input[la+q]>2{return -1}}
        required:=n*k;if output==nil||capacity<usize(required){return -2};mut error:=[32]f64{};mut staged:=[32]f64{}
        for u in 0..users{for e in rows[u]..rows[u+1]{v:=cols[e];mut estimate:=0.0;for j in 0..k{estimate+=input[la+u*k+j]*input[la+v*k+j]};delta:=input[ra+e]-estimate;for j in 0..k{error[u*k+j]+=input[la+v*k+j]*delta}}}
        for v in 0..n{for j in 0..k{q:=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+error[q])}}
        for q in 0..required{output[q]=staged[q]};return i64(required)
    }
}
