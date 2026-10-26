import math
@[export: 'graphai_frontier_sampler']
pub fn graphai_frontier_sampler(input &f64,length usize,mut output &f64,capacity usize)i64 {
    unsafe {
        if input==nil||length<3||length>124{return -1};for q in 0..length{if !input[q].is_finite(){return -1}}
        nv,mv,rv:=input[0],input[1],input[2]
        if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(rv)!=rv||nv<1||nv>8||mv<0||mv>24||rv<1||rv>4{return -1}
        n,m,r:=int(nv),int(mv),int(rv);required:=22*r;if length!=usize(4+n+m+22*r){return -1}
        root_at:=3;row_at:=root_at+r;col_at:=row_at+n+1;choice_at:=col_at+m
        mut rows:=[9]int{};mut cols:=[24]int{};mut front:=[48]int{};mut next:=[48]int{};mut staged:=[88]f64{}
        for i in 0..r{x:=input[root_at+i];if math.trunc(x)!=x||x<0||x>=f64(n){return -1};front[i]=int(x);staged[i]=x}
        if input[row_at]!=0||input[col_at-1]!=f64(m){return -1}
        for i in 0..n+1{x:=input[row_at+i];if math.trunc(x)!=x||x<0||x>f64(m){return -1};rows[i]=int(x);if i>0&&rows[i]<rows[i-1]{return -1}}
        for e in 0..m{x:=input[col_at+e];if math.trunc(x)!=x||x<0||x>=f64(n){return -1};cols[e]=int(x)}
        if output==nil||capacity<usize(required){return -2}
        fanouts:=[3]int{3,2,2};mut front_size:=r;mut choice:=0;mut out_at:=r
        for round in 0..3{fanout:=fanouts[round];next_size:=front_size*fanout
            for i in 0..front_size{parent:=front[i];begin:=rows[parent];degree:=rows[parent+1]-begin;if degree==0{return -1}
                for j in 0..fanout{x:=input[choice_at+choice];choice+=1;if math.trunc(x)!=x||x<0||x>=f64(degree){return -1};vertex:=cols[begin+int(x)];next[i*fanout+j]=vertex;staged[out_at]=f64(vertex);out_at+=1}
            }
            for i in 0..next_size{front[i]=next[i]};front_size=next_size
        }
        if choice!=21*r||out_at!=required{return -1};for q in 0..required{output[q]=staged[q]};return i64(required)
    }
}
