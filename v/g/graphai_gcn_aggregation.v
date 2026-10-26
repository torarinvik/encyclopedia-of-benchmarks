import math
@[export: 'graphai_gcn_aggregation']
pub fn graphai_gcn_aggregation(input &f64,length usize,mut output &f64,capacity usize)i64 {
    unsafe {
        if input==nil||length<7||length>84{return -1}
        for q in 0..length { if !input[q].is_finite(){return -1} }
        nv,mv,dv:=input[0],input[1],input[2]
        if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(dv)!=dv||nv<1||nv>8||mv<0||mv>24||dv<1||dv>4{return -1}
        n,m,d:=int(nv),int(mv),int(dv);if length!=usize(4+3*n+m+n*d){return -1}
        oa:=3;ea:=oa+n+1;la:=ea+m;ra:=la+n;fa:=ra+n
        if input[oa]!=0||input[ea-1]!=f64(m){return -1}
        mut rowptr:=[9]int{};mut colind:=[24]int{}
        for i in 0..n+1 { x:=input[oa+i];if math.trunc(x)!=x||x<0||x>f64(m){return -1};rowptr[i]=int(x);if i>0&&rowptr[i]<rowptr[i-1]{return -1} }
        for e in 0..m { x:=input[ea+e];if math.trunc(x)!=x||x<0||x>=f64(n){return -1};colind[e]=int(x) }
        for i in 0..n { if input[la+i]<-4||input[la+i]>4||input[ra+i]<-4||input[ra+i]>4{return -1} }
        for q in 0..n*d { if input[fa+q]<-8||input[fa+q]>8{return -1} }
        required:=n*d;if output==nil||capacity<usize(required){return -2};mut staged:=[32]f64{}
        for src in 0..n { for e in rowptr[src]..rowptr[src+1] { dst:=colind[e];weight:=input[la+src]*input[ra+dst];for k in 0..d { staged[src*d+k]+=weight*input[fa+dst*d+k] } } }
        for q in 0..required { output[q]=staged[q] };return i64(required)
    }
}
