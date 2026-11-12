module static_rectangle_add_rectangle_sum

const max_n = 32
const max_q = 32
const max_coords = 128
const stride = 129
const modulus = i64(998244353)

fn lower(a []i64, n int, x i64) int {
	mut lo := 0
	mut hi := n
	for lo < hi { mid := lo + (hi-lo)/2; if a[mid] < x { lo=mid+1 } else { hi=mid } }
	return lo
}

fn put64(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'static_rectangle_add_rectangle_sum']
pub fn static_rectangle_add_rectangle_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 291 { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv); q := int(qv)
	if length != usize(2+5*n+4*q) { return -1 }
	mut ul:=[]i64{len:max_n};mut ud:=[]i64{len:max_n};mut ur:=[]i64{len:max_n};mut uu:=[]i64{len:max_n};mut uw:=[]i64{len:max_n}
	mut ql:=[]i64{len:max_q};mut qd:=[]i64{len:max_q};mut qr:=[]i64{len:max_q};mut qu:=[]i64{len:max_q}
	mut xs:=[]i64{len:max_coords};mut ys:=[]i64{len:max_coords};mut nx:=0;mut ny:=0;mut off:=2
	for i in 0 .. n {
		ul[i]=unsafe{input[off]};ud[i]=unsafe{input[off+1]};ur[i]=unsafe{input[off+2]};uu[i]=unsafe{input[off+3]};uw[i]=unsafe{input[off+4]};off+=5
		if ul[i]<0||ul[i]>=ur[i]||ur[i]>1_000_000||ud[i]<0||ud[i]>=uu[i]||uu[i]>1_000_000||uw[i]<0||uw[i]>=modulus{return -1}
		xs[nx]=ul[i];xs[nx+1]=ur[i];ys[ny]=ud[i];ys[ny+1]=uu[i];nx+=2;ny+=2
	}
	for i in 0 .. q {
		ql[i]=unsafe{input[off]};qd[i]=unsafe{input[off+1]};qr[i]=unsafe{input[off+2]};qu[i]=unsafe{input[off+3]};off+=4
		if ql[i]<0||ql[i]>=qr[i]||qr[i]>1_000_000||qd[i]<0||qd[i]>=qu[i]||qu[i]>1_000_000{return -1}
		xs[nx]=ql[i];xs[nx+1]=qr[i];ys[ny]=qd[i];ys[ny+1]=qu[i];nx+=2;ny+=2
	}
	for i in 1 .. nx { value:=xs[i];mut j:=i;for j>0&&xs[j-1]>value{xs[j]=xs[j-1];j--};xs[j]=value }
	for i in 1 .. ny { value:=ys[i];mut j:=i;for j>0&&ys[j-1]>value{ys[j]=ys[j-1];j--};ys[j]=value }
	mut count:=0;for i in 0 .. nx {if count==0||xs[i]!=xs[count-1]{xs[count]=xs[i];count++}};nx=count
	count=0;for i in 0 .. ny {if count==0||ys[i]!=ys[count-1]{ys[count]=ys[i];count++}};ny=count
	mut diff:=[]i64{len:max_coords*max_coords};mut prefix:=[]i64{len:stride*stride}
	for k in 0 .. n {x0:=lower(xs,nx,ul[k]);x1:=lower(xs,nx,ur[k]);y0:=lower(ys,ny,ud[k]);y1:=lower(ys,ny,uu[k]);diff[x0*max_coords+y0]+=uw[k];diff[x1*max_coords+y0]-=uw[k];diff[x0*max_coords+y1]-=uw[k];diff[x1*max_coords+y1]+=uw[k]}
	for i in 0 .. nx {for j in 0 .. ny {at:=i*max_coords+j;mut value:=diff[at];if i>0{value+=diff[(i-1)*max_coords+j]};if j>0{value+=diff[i*max_coords+j-1]};if i>0&&j>0{value-=diff[(i-1)*max_coords+j-1]};diff[at]=value}}
	if nx>1&&ny>1 {for i in 0 .. nx-1 {for j in 0 .. ny-1 {value:=diff[i*max_coords+j]%modulus;dx:=(xs[i+1]-xs[i])%modulus;dy:=(ys[j+1]-ys[j])%modulus;cell:=value*(dx*dy%modulus)%modulus;at:=(i+1)*stride+j+1;mut sum:=(cell+prefix[i*stride+j+1]+prefix[(i+1)*stride+j]-prefix[i*stride+j])%modulus;if sum<0{sum+=modulus};prefix[at]=sum}}}
	mut answer:=[]i64{len:max_q}
	for k in 0 .. q {x0:=lower(xs,nx,ql[k]);x1:=lower(xs,nx,qr[k]);y0:=lower(ys,ny,qd[k]);y1:=lower(ys,ny,qu[k]);mut value:=prefix[x1*stride+y1]-prefix[x0*stride+y1]-prefix[x1*stride+y0]+prefix[x0*stride+y0];value%=modulus;if value<0{value+=modulus};answer[k]=value}
	bytes:=8*q;if unsafe{output==nil}||capacity<usize(bytes){return -2};for k in 0 .. q{put64(mut output,8*k,answer[k])};return i64(bytes)
}
