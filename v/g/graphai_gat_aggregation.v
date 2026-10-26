import math
@[export: 'graphai_gat_aggregation']
pub fn graphai_gat_aggregation(input &f64,length usize,mut output &f64,capacity usize)i64 {
    unsafe {
        if input==nil||length<3||length>76{return -1};for q in 0..length{if !input[q].is_finite(){return -1}}
        nv,mv,dv:=input[0],input[1],input[2]
        if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(dv)!=dv||nv<1||nv>8||mv<0||mv>24||dv<1||dv>4{return -1}
        n,m,d:=int(nv),int(mv),int(dv);if length!=usize(4+n+m+2*d+n*d){return -1};rp:=3;ci:=rp+n+1;al:=ci+m;ar:=al+d;xf:=ar+d
        if input[rp]!=0||input[ci-1]!=f64(m){return -1};mut rows:=[9]int{};mut cols:=[24]int{}
        for i in 0..n+1{x:=input[rp+i];if math.trunc(x)!=x||x<0||x>f64(m){return -1};rows[i]=int(x);if i>0&&rows[i]<rows[i-1]{return -1}}
        for e in 0..m{x:=input[ci+e];if math.trunc(x)!=x||x<0||x>=f64(n){return -1};cols[e]=int(x)}
        for q in al..length{if input[q]<-8||input[q]>8{return -1}}
        required:=n*d;if output==nil||capacity<usize(required){return -2};mut staged:=[32]f64{};mut scores:=[24]f64{};mut weights:=[24]f64{}
        for src in 0..n{begin,end:=rows[src],rows[src+1];if begin<end{maximum:= -1.0e300
            for e in begin..end{dst:=cols[e];mut score:=0.0;for k in 0..d{score+=input[al+k]*input[xf+src*d+k]};for k in 0..d{score+=input[ar+k]*input[xf+dst*d+k]};scores[e]=if score>0{score}else{0.2*score};if scores[e]>maximum{maximum=scores[e]}}
            mut total:=0.0;for e in begin..end{weights[e]=math.exp(scores[e]-maximum);total+=weights[e]}
            for e in begin..end{dst:=cols[e];scale:=weights[e]/total;for k in 0..d{staged[src*d+k]+=scale*input[xf+dst*d+k]}}
        }}
        for q in 0..required{output[q]=staged[q]};return i64(required)
    }
}
