// Clean-room bounded Heartwall score/selection; see package LICENSE.txt.
fn addf(a:f32,b:f32)->f32{a+b} fn subf(a:f32,b:f32)->f32{a-b} fn mulf(a:f32,b:f32)->f32{a*b} fn divf(a:f32,b:f32)->f32{a/b}
fn put64(o:&mut [u8],x:i64){o[..8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn rodinia_heartwall_template_match(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<5||n>85{return -1;}let a=std::slice::from_raw_parts(v,n);let(ir0,ic0,tr0,tc0,mask)=(a[0],a[1],a[2],a[3],a[4]);
 if !(2..=8).contains(&ir0)||!(2..=8).contains(&ic0)||!(2..=4).contains(&tr0)||!(2..=4).contains(&tc0)||tr0>ir0||tc0>ic0||mask<0{return -1;}
 let(ir,ic,tr,tc)=(ir0 as usize,ic0 as usize,tr0 as usize,tc0 as usize);let(nr,nc)=(ir-tr+1,ic-tc+1);let count=nr*nc;
 if (mask as u64>>count)!=0||n!=5+tr*tc+ir*ic||a[5..].iter().any(|&x|!(0..=255).contains(&x)){return -1;}
 let(nn,ibase)=(tr*tc,5+tr*tc);let mut tsum=0f32;let mut tsq=0f32;
 for c in 0..tc{for r in 0..tr{let x=a[5+c*tr+r] as f32;tsum=addf(tsum,x);tsq=addf(tsq,mulf(x,x));}}
 let nf=nn as f32;let tm=divf(tsum,nf);let tv=subf(divf(tsq,nf),mulf(tm,tm));if !(tv>0.0){return -1;}
 let mut best=0f32;let mut besti=0usize;let mut k=0usize;
 for c0 in 0..nc{for r0 in 0..nr{if ((mask as u64>>k)&1)!=0{let(mut ps,mut pq,mut dot)=(0f32,0f32,0f32);
  for c in 0..tc{for r in 0..tr{let x=a[5+c*tr+r] as f32;let y=a[ibase+(c0+c)*ir+r0+r] as f32;ps=addf(ps,y);pq=addf(pq,mulf(y,y));dot=addf(dot,mulf(x,y));}}
  let mut centered=subf(pq,divf(mulf(ps,ps),nf));if centered<0.0{centered=0.0;}if !(centered>0.0){return -1;}
  let num=subf(dot,divf(mulf(ps,tsum),nf));let denom_t=((nn-1) as f32).sqrt()*tv.sqrt();let den=centered.sqrt()*denom_t;let score=divf(num,den);let mag=score.abs();if !mag.is_finite(){return -1;}if mag>best{best=mag;besti=k;}}
 k+=1;}}
 if out.is_null()||cap<8{return -2;}put64(std::slice::from_raw_parts_mut(out,8),besti as i64);8
}
