package private_noisy_power_iteration
import "core:c"

S :: i64(1_000_000)
MAX_N :: 4
MAX_L :: 4
MAX_INPUT :: 39

trunc_div :: proc(value, denominator: i64) -> i64 {
    if value < 0 { return -((-value)/denominator) }
    return value/denominator
}
floor_sqrt :: proc(value: i64) -> i64 {
    low: i64=0; high: i64=13_000_001
    for low+1<high {
        middle:=(low+high)/2
        if middle<=value/middle { low=middle } else { high=middle }
    }
    return low
}
put64 :: proc(out: [^]u8, pos: int, value: i64) {
    bits:=u64(value)
    for j:=0;j<8;j+=1 { out[pos+j]=u8(bits&255);bits>>=8 }
}

@(export)
private_noisy_power_iteration :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<11 || length>MAX_INPUT do return -1
    n64:=input[0];rounds64:=input[1];sigma:=input[2]
    if n64<2 || n64>MAX_N || rounds64<1 || rounds64>MAX_L || sigma<0 || sigma>S do return -1
    n:=int(n64);rounds:=int(rounds64);expected:=3+n*n+n+rounds*n
    if length!=c.size_t(expected) do return -1
    vector_start:=3+n*n;noise_start:=vector_start+n
    matrix:[16]i64;x:[4]i64;noise:[16]i64
    for i:=0;i<n*n;i+=1 { matrix[i]=input[3+i];if matrix[i]<-S||matrix[i]>S do return -1 }
    for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { if matrix[i*n+j]!=matrix[j*n+i] do return -1 } }
    initial_norm:i64=0
    for i:=0;i<n;i+=1 { x[i]=input[vector_start+i];if x[i]<-S||x[i]>S do return -1;initial_norm+=x[i]*x[i] }
    if initial_norm!=S*S do return -1
    for i:=0;i<rounds*n;i+=1 { noise[i]=input[noise_start+i];if noise[i]<-2*S||noise[i]>2*S do return -1 }
    y:[4]i64
    for step:=0;step<rounds;step+=1 {
        norm_sq:i64=0
        for i:=0;i<n;i+=1 { sum:=sigma*noise[step*n+i];for j:=0;j<n;j+=1 { sum+=matrix[i*n+j]*x[j] };y[i]=trunc_div(sum,S);norm_sq+=y[i]*y[i] }
        if norm_sq==0 do return -1
        radius:=floor_sqrt(norm_sq)
        for i:=0;i<n;i+=1 { x[i]=trunc_div(y[i]*S,radius) }
    }
    bytes:=8*n
    if output==nil || capacity<c.size_t(bytes) do return -2
    staged:[32]u8
    for i:=0;i<n;i+=1 { put64(&staged[0],8*i,x[i]) }
    for i:=0;i<bytes;i+=1 { output[i]=staged[i] }
    return i64(bytes)
}
