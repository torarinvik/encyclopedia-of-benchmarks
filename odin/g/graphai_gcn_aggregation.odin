package graphai_gcn_aggregation
import "core:c"
import "core:math"
@(export)
graphai_gcn_aggregation :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
    N :: 8; M :: 24; D :: 4; MAX_INPUT :: 4+3*N+M+N*D
    if input==nil||length<7||length>c.size_t(MAX_INPUT) do return -1
    for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
    nv,mv,dv:=input[0],input[1],input[2]
    if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(dv)!=dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D do return -1
    n,m,d:=int(nv),int(mv),int(dv);if length!=c.size_t(4+3*n+m+n*d) do return -1
    oa:=3;ea:=oa+n+1;la:=ea+m;ra:=la+n;fa:=ra+n
    if input[oa]!=0||input[ea-1]!=f64(m) do return -1
    var rowptr:[9]int;var colind:[24]int
    for i:=0;i<=n;i+=1 { x:=input[oa+i];if math.trunc(x)!=x||x<0||x>f64(m) do return -1;rowptr[i]=int(x);if i>0&&rowptr[i]<rowptr[i-1] do return -1 }
    for e:=0;e<m;e+=1 { x:=input[ea+e];if math.trunc(x)!=x||x<0||x>=f64(n) do return -1;colind[e]=int(x) }
    for i:=0;i<n;i+=1 { if input[la+i]<-4||input[la+i]>4||input[ra+i]<-4||input[ra+i]>4 do return -1 }
    for q:=0;q<n*d;q+=1 { if input[fa+q]<-8||input[fa+q]>8 do return -1 }
    required:=n*d;if output==nil||capacity<c.size_t(required) do return -2
    var staged:[32]f64
    for src:=0;src<n;src+=1 { for e:=rowptr[src];e<rowptr[src+1];e+=1 { dst:=colind[e];weight:=input[la+src]*input[ra+dst];for k:=0;k<d;k+=1 { staged[src*d+k]+=weight*input[fa+dst*d+k] } } }
    for q:=0;q<required;q+=1 { output[q]=staged[q] }
    return i64(required)
}
