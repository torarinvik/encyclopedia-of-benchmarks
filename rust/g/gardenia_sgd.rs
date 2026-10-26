// Clean-room bounded sequential GARDENIA MF-SGD profile.
#[no_mangle]
pub unsafe extern "C" fn gardenia_sgd(a:*const f64,len:usize,out:*mut f64,cap:usize)->i64{
    const N:usize=8;const M:usize=24;const K:usize=4;const IMAX:usize=92;
    if a.is_null()||len<4||len>IMAX{return -1;}for q in 0..len{if !(*a.add(q)).is_finite(){return -1;}}
    let uv=*a;let iv=*a.add(1);let mv=*a.add(2);let kv=*a.add(3);if uv.fract()!=0.0||iv.fract()!=0.0||mv.fract()!=0.0||kv.fract()!=0.0||uv<1.0||uv>7.0||iv<1.0||iv>7.0||mv<1.0||mv>M as f64||kv<1.0||kv>K as f64{return -1;}
    let users=uv as usize;let items=iv as usize;let m=mv as usize;let k=kv as usize;let n=users+items;if n>N||len!=5+users+2*m+n*k{return -1;}
    let rp=4;let ci=rp+users+1;let ra=ci+m;let la=ra+m;let mut rows=[0usize;N+1];let mut cols=[0usize;M];let mut ratings=[0.0;M];let mut latent=[0.0;N*K];let mut errors=[0.0;N];let mut staged=[0.0;N*K];
    for i in 0..=users{let z=*a.add(rp+i);if z.fract()!=0.0||z<0.0||z>m as f64{return -1;}rows[i]=z as usize;if i>0&&rows[i]<rows[i-1]{return -1;}}if rows[0]!=0||rows[users]!=m{return -1;}
    for e in 0..m{let z=*a.add(ci+e);if z.fract()!=0.0||z<0.0||z>=items as f64{return -1;}cols[e]=z as usize;ratings[e]=*a.add(ra+e);if ratings[e] < -4.0||ratings[e]>4.0{return -1;}}
    for q in 0..n*k{latent[q]=*a.add(la+q);if latent[q]<0.0||latent[q]>0.1{return -1;}}let required=n*k;if out.is_null()||cap<required{return -2;}
    for _ in 0..3{for u in 0..users{errors[u]=0.0;}for u in 0..users{for e in rows[u]..rows[u+1]{let v=users+cols[e];let mut estimate=0.0;for f in 0..k{estimate+=latent[u*k+f]*latent[v*k+f];}let delta=ratings[e]-estimate;errors[u]+=delta*delta;for f in 0..k{let ui=u*k+f;let vi=v*k+f;let pu=latent[ui];let pi=latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta);}}}let mut total=0.0;for u in 0..users{total+=errors[u];}if (total/(m as f64)).sqrt()<0.1{break;}}
    staged[..required].copy_from_slice(&latent[..required]);std::ptr::copy_nonoverlapping(staged.as_ptr(),out,required);required as i64
}
