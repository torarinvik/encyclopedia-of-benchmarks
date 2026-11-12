package static_rectangle_add_rectangle_sum

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_COORDS :: 128
STRIDE :: 129
MOD :: i64(998244353)

lower :: proc "contextless" (a: [^]i64, n: int, x: i64) -> int {
	lo, hi := 0, n
	for lo < hi { mid := lo + (hi-lo)/2; if a[mid] < x { lo=mid+1 } else { hi=mid } }
	return lo
}

put64 :: proc "contextless" (output: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[at+b]=u8((bits>>(8*b))&255) }
}

@(export)
static_rectangle_add_rectangle_sum :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 291 do return -1
	n64,q64 := input[0],input[1]
	if n64<1 || n64>32 || q64<0 || q64>32 do return -1
	n,q := int(n64),int(q64)
	if int(length)!=2+5*n+4*q do return -1
	ul,ud,ur,uu,uw := [MAX_N]i64{},[MAX_N]i64{},[MAX_N]i64{},[MAX_N]i64{},[MAX_N]i64{}
	ql,qd,qr,qu := [MAX_Q]i64{},[MAX_Q]i64{},[MAX_Q]i64{},[MAX_Q]i64{}
	xs,ys := [MAX_COORDS]i64{},[MAX_COORDS]i64{}
	nx,ny,off := 0,0,2
	for i:=0;i<n;i+=1 {
		ul[i]=input[off];ud[i]=input[off+1];ur[i]=input[off+2];uu[i]=input[off+3];uw[i]=input[off+4];off+=5
		if ul[i]<0 || ul[i]>=ur[i] || ur[i]>1000000 || ud[i]<0 || ud[i]>=uu[i] || uu[i]>1000000 || uw[i]<0 || uw[i]>=MOD do return -1
		xs[nx]=ul[i];xs[nx+1]=ur[i];ys[ny]=ud[i];ys[ny+1]=uu[i];nx+=2;ny+=2
	}
	for i:=0;i<q;i+=1 {
		ql[i]=input[off];qd[i]=input[off+1];qr[i]=input[off+2];qu[i]=input[off+3];off+=4
		if ql[i]<0 || ql[i]>=qr[i] || qr[i]>1000000 || qd[i]<0 || qd[i]>=qu[i] || qu[i]>1000000 do return -1
		xs[nx]=ql[i];xs[nx+1]=qr[i];ys[ny]=qd[i];ys[ny+1]=qu[i];nx+=2;ny+=2
	}
	for i:=1;i<nx;i+=1 {value:=xs[i];j:=i;for j>0&&xs[j-1]>value{xs[j]=xs[j-1];j-=1};xs[j]=value}
	for i:=1;i<ny;i+=1 {value:=ys[i];j:=i;for j>0&&ys[j-1]>value{ys[j]=ys[j-1];j-=1};ys[j]=value}
	count:=0;for i:=0;i<nx;i+=1{if count==0||xs[i]!=xs[count-1]{xs[count]=xs[i];count+=1}};nx=count
	count=0;for i:=0;i<ny;i+=1{if count==0||ys[i]!=ys[count-1]{ys[count]=ys[i];count+=1}};ny=count
	diff := [MAX_COORDS*MAX_COORDS]i64{}
	prefix := [STRIDE*STRIDE]i64{}
	for k:=0;k<n;k+=1{x0:=lower(&xs[0],nx,ul[k]);x1:=lower(&xs[0],nx,ur[k]);y0:=lower(&ys[0],ny,ud[k]);y1:=lower(&ys[0],ny,uu[k]);diff[x0*MAX_COORDS+y0]+=uw[k];diff[x1*MAX_COORDS+y0]-=uw[k];diff[x0*MAX_COORDS+y1]-=uw[k];diff[x1*MAX_COORDS+y1]+=uw[k]}
	for i:=0;i<nx;i+=1{for j:=0;j<ny;j+=1{at:=i*MAX_COORDS+j;v:=diff[at];if i>0{v+=diff[(i-1)*MAX_COORDS+j]};if j>0{v+=diff[i*MAX_COORDS+j-1]};if i>0&&j>0{v-=diff[(i-1)*MAX_COORDS+j-1]};diff[at]=v}}
	if nx>1&&ny>1{for i:=0;i<nx-1;i+=1{for j:=0;j<ny-1;j+=1{v:=diff[i*MAX_COORDS+j]%MOD;dx:=(xs[i+1]-xs[i])%MOD;dy:=(ys[j+1]-ys[j])%MOD;cell:=v*(dx*dy%MOD)%MOD;at:=(i+1)*STRIDE+j+1;sum:=(cell+prefix[i*STRIDE+j+1]+prefix[(i+1)*STRIDE+j]-prefix[i*STRIDE+j])%MOD;if sum<0{sum+=MOD};prefix[at]=sum}}}
	answer := [MAX_Q]i64{}
	for k:=0;k<q;k+=1{x0:=lower(&xs[0],nx,ql[k]);x1:=lower(&xs[0],nx,qr[k]);y0:=lower(&ys[0],ny,qd[k]);y1:=lower(&ys[0],ny,qu[k]);v:=prefix[x1*STRIDE+y1]-prefix[x0*STRIDE+y1]-prefix[x1*STRIDE+y0]+prefix[x0*STRIDE+y0];v%=MOD;if v<0{v+=MOD};answer[k]=v}
	bytes:=8*q
	if output==nil || int(capacity)<bytes do return -2
	for k:=0;k<q;k+=1{put64(output,8*k,answer[k])}
	return i64(bytes)
}
