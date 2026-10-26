package graphai_frontier_sampler
import "core:c"
import "core:math"
@(export)
graphai_frontier_sampler :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
    N :: 8;M :: 24;R :: 4;MAX_INPUT :: 4+N+M+22*R
    if input==nil||length<3||length>c.size_t(MAX_INPUT) do return -1
    for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
    nv,mv,rv:=input[0],input[1],input[2]
    if math.trunc(nv)!=nv||math.trunc(mv)!=mv||math.trunc(rv)!=rv||nv<1||nv>N||mv<0||mv>M||rv<1||rv>R do return -1
    n,m,r:=int(nv),int(mv),int(rv);required:=22*r;if length!=c.size_t(4+n+m+22*r) do return -1
    root_at:=3;row_at:=root_at+r;col_at:=row_at+n+1;choice_at:=col_at+m
    var rows:[9]int;var cols:[24]int;var front:[48]int;var next:[48]int;var staged:[88]f64
    for i:=0;i<r;i+=1 { x:=input[root_at+i];if math.trunc(x)!=x||x<0||x>=f64(n) do return -1;front[i]=int(x);staged[i]=x }
    if input[row_at]!=0||input[col_at-1]!=f64(m) do return -1
    for i:=0;i<=n;i+=1 { x:=input[row_at+i];if math.trunc(x)!=x||x<0||x>f64(m) do return -1;rows[i]=int(x);if i>0&&rows[i]<rows[i-1] do return -1 }
    for e:=0;e<m;e+=1 { x:=input[col_at+e];if math.trunc(x)!=x||x<0||x>=f64(n) do return -1;cols[e]=int(x) }
    if output==nil||capacity<c.size_t(required) do return -2
    fanouts:=[3]int{3,2,2};front_size:=r;choice:=0;out_at:=r
    for round:=0;round<3;round+=1 { fanout:=fanouts[round];next_size:=front_size*fanout
        for i:=0;i<front_size;i+=1 { parent:=front[i];begin:=rows[parent];degree:=rows[parent+1]-begin;if degree==0 do return -1
            for j:=0;j<fanout;j+=1 { x:=input[choice_at+choice];choice+=1;if math.trunc(x)!=x||x<0||x>=f64(degree) do return -1;vertex:=cols[begin+int(x)];next[i*fanout+j]=vertex;staged[out_at]=f64(vertex);out_at+=1 }
        }
        for i:=0;i<next_size;i+=1 { front[i]=next[i] };front_size=next_size
    }
    if choice!=21*r||out_at!=required do return -1
    for q:=0;q<required;q+=1 { output[q]=staged[q] };return i64(required)
}
