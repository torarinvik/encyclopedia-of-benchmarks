package graphai_gat_aggregation
import "core:c"
import "core:math"
@(export)
graphai_gat_aggregation :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
    N :: 8;M :: 24;D :: 4;MAX_INPUT :: 4+N+M+2*D+N*D
    if input==nil||length<3||length>c.size_t(MAX_INPUT) do return -1
    for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
    nv,mv,dv:=input[0],input[1],input[2]
    if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(dv)!=dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D do return -1
    n,m,d:=int(nv),int(mv),int(dv);if length!=c.size_t(4+n+m+2*d+n*d) do return -1
    rp:=3;ci:=rp+n+1;al:=ci+m;ar:=al+d;xf:=ar+d
    if input[rp]!=0||input[ci-1]!=f64(m) do return -1
    var rows:[9]int;var cols:[24]int
    for i:=0;i<=n;i+=1 { x:=input[rp+i];if math.trunc(x)!=x||x<0||x>f64(m) do return -1;rows[i]=int(x);if i>0&&rows[i]<rows[i-1] do return -1 }
    for e:=0;e<m;e+=1 { x:=input[ci+e];if math.trunc(x)!=x||x<0||x>=f64(n) do return -1;cols[e]=int(x) }
    for q:=al;q<int(length);q+=1 { if input[q]<-8||input[q]>8 do return -1 }
    required:=n*d;if output==nil||capacity<c.size_t(required) do return -2
    var staged:[32]f64;var scores:[24]f64;var weights:[24]f64
    for src:=0;src<n;src+=1 { begin,end:=rows[src],rows[src+1];if begin<end { maximum:= -1.0e300
        for e:=begin;e<end;e+=1 { dst:=cols[e];score:=0.0;for k:=0;k<d;k+=1 { score+=input[al+k]*input[xf+src*d+k] };for k:=0;k<d;k+=1 { score+=input[ar+k]*input[xf+dst*d+k] };scores[e]=score;if score<=0 { scores[e]=0.2*score };if scores[e]>maximum { maximum=scores[e] } }
        total:=0.0;for e:=begin;e<end;e+=1 { weights[e]=math.exp(scores[e]-maximum);total+=weights[e] }
        for e:=begin;e<end;e+=1 { dst:=cols[e];scale:=weights[e]/total;for k:=0;k<d;k+=1 { staged[src*d+k]+=scale*input[xf+dst*d+k] } }
    } }
    for q:=0;q<required;q+=1 { output[q]=staged[q] };return i64(required)
}
