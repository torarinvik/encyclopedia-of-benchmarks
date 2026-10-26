// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
import math

const polarity = [20]f64{8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9}
const volume = [20]f64{31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0}

fn amino_channel(code i64) int {
	if code==65{return 0};if code==82{return 1};if code==78{return 2};if code==68{return 3};if code==67{return 4}
	if code==81{return 5};if code==69{return 6};if code==71{return 7};if code==72{return 8};if code==73{return 9}
	if code==76{return 10};if code==75{return 11};if code==77{return 12};if code==70{return 13};if code==80{return 14}
	if code==83{return 15};if code==84{return 16};if code==87{return 17};if code==89{return 18};if code==86{return 19};return -1
}
fn fft(mut re []f64, mut im []f64, offset int, n int, inverse bool) {
	mut j:=0
	for i in 1..n {mut bit:=n>>1;for (j&bit)!=0 {j^=bit;bit>>=1};j^=bit;if i<j {re[offset+i],re[offset+j]=re[offset+j],re[offset+i];im[offset+i],im[offset+j]=im[offset+j],im[offset+i]}}
	mut span:=2
	for span<=n {direction:=if inverse {1.0} else {-1.0};angle:=direction*6.2831853071795864769/f64(span);cr:=math.cos(angle);ci:=math.sin(angle);mut start:=0
		for start<n {mut wr:=1.0;mut wi:=0.0;for k in 0..span/2 {u:=offset+start+k;v:=u+span/2;pr:=wr*re[v]-wi*im[v];pi:=wr*im[v]+wi*re[v];ur:=re[u];ui:=im[u];re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;nw:=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw};start+=span}
		span*=2
	}
	if !inverse {for q in 0..n {re[offset+q]/=f64(n);im[offset+q]/=f64(n)}}
}

@[export: 'mafft_falign_fft_lag_correlation']
pub fn mafft_falign_fft_lag_correlation(input &f64,length usize,mut output &f64,capacity usize)i64 {
	unsafe {
		if input==nil||length<4||length>66{return -1}
		for q in 0..length {v:=input[q];if !v.is_finite()||math.trunc(v)!=v{return -1}}
		if input[0]<1||input[0]>32||input[1]<1||input[1]>32{return -1}
		n1,n2:=int(input[0]),int(input[1]);if length!=usize(2+n1+n2){return -1}
		for q in 2..length {if input[q]<65||input[q]>90||amino_channel(i64(input[q]))<0{return -1}}
		mut n:=1;longer:=if n1>n2 {n1} else {n2};for n<=longer {n*=2};if output==nil||capacity<usize(n){return -2}
		mut r1:=[]f64{len:1280,init:0.0};mut i1:=[]f64{len:1280,init:0.0};mut r2:=[]f64{len:1280,init:0.0};mut i2:=[]f64{len:1280,init:0.0};mut re:=[]f64{len:64,init:0.0};mut im:=[]f64{len:64,init:0.0}
		mut mp:=0.0;mut mv:=0.0
		for ch in 0..20 {mp+=polarity[ch];mv+=volume[ch]}
		mp/=20.0;mv/=20.0
		mut vp:=0.0;mut vv:=0.0
		for ch in 0..20 {dp:=polarity[ch]-mp;dv:=volume[ch]-mv;vp+=dp*dp;vv+=dv*dv}
		sp:=math.sqrt(vp/20.0);sv:=math.sqrt(vv/20.0)
		for p in 0..n1 {ch:=amino_channel(i64(input[2+p]));r1[p]=(polarity[ch]-mp)/sp;i1[p]=(volume[ch]-mv)/sv}
		for p in 0..n2 {ch:=amino_channel(i64(input[2+n1+p]));r2[p]=(polarity[ch]-mp)/sp;i2[p]=(volume[ch]-mv)/sv}
		fft(mut r1,mut i1,0,n,false);fft(mut r2,mut i2,0,n,false)
		for k in 0..n {re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]= -r1[k]*i2[k]+i1[k]*r2[k]}
		fft(mut re,mut im,0,n,true);for q in 0..n {output[q]=re[(n/2+n-q)%n]};return i64(n)
	}
}
