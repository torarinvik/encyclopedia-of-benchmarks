import math
@[export: 'graphai_sage_aggregation']
pub fn graphai_sage_aggregation(input &f64,length usize,mut output &f64,capacity usize)i64 {
    unsafe {
        if input==nil||length<4||length>68{return -1};for q in 0..length{if !input[q].is_finite(){return -1}}
        nv,mv,dv:=input[0],input[1],input[2]
        if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(dv)!=dv||nv<1||nv>8||mv<0||mv>24||dv<1||dv>4{return -1}
        n,m,d:=int(nv),int(mv),int(dv);if length!=usize(4+n+m+n*d){return -1};rp:=3;ci:=rp+n+1;xf:=ci+m
        if input[rp]!=0||input[ci-1]!=f64(m){return -1};mut rows:=[9]int{};mut cols:=[24]int{}
        for i in 0..n+1{x:=input[rp+i];if math.trunc(x)!=x||x<0||x>f64(m){return -1};rows[i]=int(x);if i>0&&rows[i]<rows[i-1]{return -1}}
        for e in 0..m{x:=input[ci+e];if math.trunc(x)!=x||x<0||x>=f64(n){return -1};cols[e]=int(x)}
        for q in 0..n*d{if input[xf+q]<-8||input[xf+q]>8{return -1}}
        required:=n*d;if output==nil||capacity<usize(required){return -2};mut staged:=[32]f64{}
        for src in 0..n{degree:=rows[src+1]-rows[src];if degree>0{scale:=1.0/f64(degree);for e in rows[src]..rows[src+1]{dst:=cols[e];for k in 0..d{staged[src*d+k]+=scale*input[xf+dst*d+k]}}}}
        for q in 0..required{output[q]=staged[q]};return i64(required)
    }
}
