package graphai_cf_sgd_sweep
import "core:c"
import "core:math"
@(export)
graphai_cf_sgd_sweep :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
    N :: 8;M :: 24;K :: 4;MAX_INPUT :: 7+N+2*M+N*K
    if input==nil||length<6||length>c.size_t(MAX_INPUT) do return -1
    for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
    uv,iv,mv,kv:=input[0],input[1],input[2],input[3]
    if math.trunc(uv)!=uv||math.trunc(iv)!=iv||math.trunc(mv)!=mv||math.trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<0||mv>M||kv<1||kv>K do return -1
    users,items,m,k:=int(uv),int(iv),int(mv),int(kv);n:=users+items;lambda,step:=input[4],input[5]
    if n>N||lambda<0||lambda>1||step<0||step>0.01||length!=c.size_t(7+n+2*m+n*k) do return -1
    rp:=6;ci:=rp+n+1;ra:=ci+m;la:=ra+m;if input[rp]!=0||input[ci-1]!=f64(m) do return -1
    var rows:[9]int;var cols:[24]int
    for i:=0;i<=n;i+=1 { x:=input[rp+i];if math.trunc(x)!=x||x<0||x>f64(m) do return -1;rows[i]=int(x);if i>0&&rows[i]<rows[i-1] do return -1 }
    for u:=users;u<n;u+=1 { if rows[u]!=rows[u+1] do return -1 }
    for e:=0;e<m;e+=1 { x:=input[ci+e];if math.trunc(x)!=x||x<f64(users)||x>=f64(n) do return -1;cols[e]=int(x) }
    for e:=0;e<m;e+=1 { if input[ra+e]<-4||input[ra+e]>4 do return -1 };for q:=0;q<n*k;q+=1 { if input[la+q]<-2||input[la+q]>2 do return -1 }
    required:=n*k;if output==nil||capacity<c.size_t(required) do return -2;var errors:[32]f64;var staged:[32]f64
    for u:=0;u<users;u+=1 { for e:=rows[u];e<rows[u+1];e+=1 { v:=cols[e];estimate:=0.0;for j:=0;j<k;j+=1 { estimate+=input[la+u*k+j]*input[la+v*k+j] };delta:=input[ra+e]-estimate;for j:=0;j<k;j+=1 { errors[u*k+j]+=input[la+v*k+j]*delta } } }
    for v:=0;v<n;v+=1 { for j:=0;j<k;j+=1 { q:=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+errors[q]) } }
    for q:=0;q<required;q+=1 { output[q]=staged[q] };return i64(required)
}
