// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
package mafft_falign_fft_lag_correlation
import "core:c"
import "core:math"

amino_codes: [20]int = {65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86}
polarity: [20]f64 = {8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9}
volume: [20]f64 = {31,124,56,54,55,85,83,3,96,111,111,119,105,132,32.5,32,61,170,136,84}
channel :: proc(code: int) -> int {
    for q:=0;q<20;q+=1 {if amino_codes[q]==code do return q}
    return -1
}
fft :: proc "contextless" (re,im:^[1280]f64,offset,n:int,inverse:bool) {
    j:=0
    for i:=1;i<n;i+=1 {bit:=n/2;for (j&bit)!=0 {j=j~bit;bit/=2};j=j~bit;if i<j {re[offset+i],re[offset+j]=re[offset+j],re[offset+i];im[offset+i],im[offset+j]=im[offset+j],im[offset+i]}}
    span:=2
    for span<=n {direction:=f64(-1);if inverse{direction=1};angle:=direction*6.2831853071795864769/f64(span);cr:=math.cos(angle);ci:=math.sin(angle);start:=0
        for start<n {wr,wi:=1.0,0.0;for k:=0;k<span/2;k+=1 {u:=offset+start+k;v:=u+span/2;pr:=wr*re[v]-wi*im[v];pi:=wr*im[v]+wi*re[v];ur,ui:=re[u],im[u];re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;nw:=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw};start+=span}
        span*=2
    }
    if !inverse {for q:=0;q<n;q+=1 {re[offset+q]/=f64(n);im[offset+q]/=f64(n)}}
}

@(export)
mafft_falign_fft_lag_correlation :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
    if input==nil||length<4||length>66 do return -1
    for q:=0;q<int(length);q+=1 {v:=input[q];if v!=v||math.trunc(v)!=v do return -1}
    if input[0]<1||input[0]>32||input[1]<1||input[1]>32 do return -1
    n1,n2:=int(input[0]),int(input[1]);if int(length)!=2+n1+n2 do return -1
    for q:=2;q<int(length);q+=1 {if input[q]<65||input[q]>90||channel(int(input[q]))<0 do return -1}
    n:=1;longer:=n1;if n2>n1{longer=n2};for n<=longer{n*=2};if output==nil||capacity<c.size_t(n) do return -2
    var r1:[1280]f64;var i1:[1280]f64;var r2:[1280]f64;var i2:[1280]f64;var re:[1280]f64;var im:[1280]f64
    mp,mv:=0.0,0.0;for ch:=0;ch<20;ch+=1 {mp+=polarity[ch];mv+=volume[ch]};mp/=20;mv/=20
    vp,vv:=0.0,0.0;for ch:=0;ch<20;ch+=1 {dp:=polarity[ch]-mp;dv:=volume[ch]-mv;vp+=dp*dp;vv+=dv*dv};sp:=math.sqrt(vp/20);sv:=math.sqrt(vv/20)
    for p:=0;p<n1;p+=1 {ch:=channel(int(input[2+p]));r1[p]=(polarity[ch]-mp)/sp;i1[p]=(volume[ch]-mv)/sv}
    for p:=0;p<n2;p+=1 {ch:=channel(int(input[2+n1+p]));r2[p]=(polarity[ch]-mp)/sp;i2[p]=(volume[ch]-mv)/sv}
    fft(&r1,&i1,0,n,false);fft(&r2,&i2,0,n,false)
    for k:=0;k<n;k+=1 {re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]=-r1[k]*i2[k]+i1[k]*r2[k]}
    fft(&re,&im,0,n,true);for q:=0;q<n;q+=1 {output[q]=re[(n/2+n-q)%n]};return i64(n)
}
