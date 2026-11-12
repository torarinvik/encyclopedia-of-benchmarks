const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const CMAX: usize = 128;
const STRIDE: usize = 129;
const MOD: i64 = 998_244_353;

fn lower(a: &[i64; CMAX], n: usize, x: i64) -> usize {
    let (mut lo, mut hi) = (0, n);
    while lo < hi { let mid = lo + (hi-lo)/2; if a[mid] < x { lo=mid+1; } else { hi=mid; } }
    lo
}
fn put64(out: *mut u8, at: usize, value: i64) {
    let bits=value as u64;
    unsafe { for b in 0..8 { *out.add(at+b)=(bits>>(8*b)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn static_rectangle_add_rectangle_sum(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 291 { return -1; }
    let n0=*input; let q0=*input.add(1);
    if n0<1 || n0>32 || q0<0 || q0>32 { return -1; }
    let n=n0 as usize; let q=q0 as usize;
    if length!=2+5*n+4*q { return -1; }
    let mut ul=[0i64;MAX_N]; let mut ud=[0i64;MAX_N]; let mut ur=[0i64;MAX_N]; let mut uu=[0i64;MAX_N]; let mut uw=[0i64;MAX_N];
    let mut ql=[0i64;MAX_Q]; let mut qd=[0i64;MAX_Q]; let mut qr=[0i64;MAX_Q]; let mut qu=[0i64;MAX_Q];
    let mut xs=[0i64;CMAX]; let mut ys=[0i64;CMAX]; let (mut nx,mut ny)=(0usize,0usize); let mut off=2usize;
    for i in 0..n {
        ul[i]=*input.add(off);ud[i]=*input.add(off+1);ur[i]=*input.add(off+2);uu[i]=*input.add(off+3);uw[i]=*input.add(off+4);off+=5;
        if ul[i]<0||ul[i]>=ur[i]||ur[i]>1_000_000||ud[i]<0||ud[i]>=uu[i]||uu[i]>1_000_000||uw[i]<0||uw[i]>=MOD{return -1;}
        xs[nx]=ul[i];xs[nx+1]=ur[i];ys[ny]=ud[i];ys[ny+1]=uu[i];nx+=2;ny+=2;
    }
    for i in 0..q {
        ql[i]=*input.add(off);qd[i]=*input.add(off+1);qr[i]=*input.add(off+2);qu[i]=*input.add(off+3);off+=4;
        if ql[i]<0||ql[i]>=qr[i]||qr[i]>1_000_000||qd[i]<0||qd[i]>=qu[i]||qu[i]>1_000_000{return -1;}
        xs[nx]=ql[i];xs[nx+1]=qr[i];ys[ny]=qd[i];ys[ny+1]=qu[i];nx+=2;ny+=2;
    }
    xs[..nx].sort();ys[..ny].sort();
    let mut out=0usize;for read in 0..nx{let v=xs[read];if out==0||xs[out-1]!=v{xs[out]=v;out+=1;}}nx=out;
    out=0;for read in 0..ny{let v=ys[read];if out==0||ys[out-1]!=v{ys[out]=v;out+=1;}}ny=out;
    let mut diff=[0i64;CMAX*CMAX];let mut pref=[0i64;STRIDE*STRIDE];
    for k in 0..n {let x0=lower(&xs,nx,ul[k]);let x1=lower(&xs,nx,ur[k]);let y0=lower(&ys,ny,ud[k]);let y1=lower(&ys,ny,uu[k]);
        diff[x0*CMAX+y0]+=uw[k];diff[x1*CMAX+y0]-=uw[k];diff[x0*CMAX+y1]-=uw[k];diff[x1*CMAX+y1]+=uw[k];}
    for i in 0..nx {for j in 0..ny {let at=i*CMAX+j;let mut v=diff[at];if i>0{v+=diff[(i-1)*CMAX+j];}if j>0{v+=diff[i*CMAX+j-1];}if i>0&&j>0{v-=diff[(i-1)*CMAX+j-1];}diff[at]=v;}}
    for i in 0..nx.saturating_sub(1) {for j in 0..ny.saturating_sub(1) {let value=diff[i*CMAX+j]%MOD;let dx=(xs[i+1]-xs[i])%MOD;let dy=(ys[j+1]-ys[j])%MOD;let cell=value*(dx*dy%MOD)%MOD;let at=(i+1)*STRIDE+j+1;let mut sum=(cell+pref[i*STRIDE+j+1]+pref[(i+1)*STRIDE+j]-pref[i*STRIDE+j])%MOD;if sum<0{sum+=MOD;}pref[at]=sum;}}
    let mut answers=[0i64;MAX_Q];
    for k in 0..q {let x0=lower(&xs,nx,ql[k]);let x1=lower(&xs,nx,qr[k]);let y0=lower(&ys,ny,qd[k]);let y1=lower(&ys,ny,qu[k]);let mut v=pref[x1*STRIDE+y1]-pref[x0*STRIDE+y1]-pref[x1*STRIDE+y0]+pref[x0*STRIDE+y0];v%=MOD;if v<0{v+=MOD;}answers[k]=v;}
    let bytes=8*q;if output.is_null()||capacity<bytes{return -2;}for k in 0..q{put64(output,8*k,answers[k]);}bytes as i64
}
