package sensor_energy_balance_estimator_trace

import "core:c"

MAX_N :: 8
MAX_INPUT :: 82
INPUT_SCALE :: i64(1_000_000)

gcd :: proc(a0,b0:i64)->i64{a,b:=a0,b0;for b!=0{r:=a%b;a,b=b,r};return a}
put64 :: proc(output:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits&255);bits>>=8}}

@(export)
sensor_energy_balance_estimator_trace :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<4||length>MAX_INPUT do return -1
    n64,h64:=input[0],input[1]
    if n64<1||n64>8||h64<1||h64>8||length!=c.size_t(2+n64+h64+n64*h64) do return -1
    n,h:=int(n64),int(h64);lambda:[MAX_N]i64;sum:i64=0
    for i:=0;i<n;i+=1{lambda[i]=input[2+i];if lambda[i]<0||lambda[i]>INPUT_SCALE do return -1;sum+=lambda[i]}
    if sum!=INPUT_SCALE do return -1
    full:=(u64(1)<<n)-1;path_at:=2+n
    for t:=0;t<h;t+=1{mask:=input[path_at+t];if mask<=0||(u64(mask)&~full)!=0 do return -1}
    lcm:i64=1;for t:i64=2;t<=h64;t+=1{lcm=(lcm/gcd(lcm,t))*t};q:=INPUT_SCALE*lcm;draw_at:=path_at+h
    for i:=0;i<n*h;i+=1{if input[draw_at+i]<0||input[draw_at+i]>=q do return -1}
    state:[MAX_N]i64;for i:=0;i<n;i+=1{state[i]=lambda[i]*lcm}
    for t:=0;t<h;t+=1{divisor:=i64(t+1);delta:=q/divisor;path:=u64(input[path_at+t]);for i:=0;i<n;i+=1{if state[i]<0||state[i]>q do return -1;r:i64=0;if input[draw_at+t*n+i]<state[i]{r=1};x:=i64((path>>i)&1);updated:=state[i]+(x-r)*delta;if updated<0||updated>q do return -1;state[i]=updated}}
    bytes:=8*(1+n);if output==nil||capacity<c.size_t(bytes) do return -2
    staged:[72]u8;put64(&staged[0],0,q);for i:=0;i<n;i+=1{put64(&staged[0],8*(i+1),state[i])};for b:=0;b<bytes;b+=1{output[b]=staged[b]}return i64(bytes)
}
