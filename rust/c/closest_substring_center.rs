/// Bounded exact closest-substring center by lexicographic exhaustive search.
#[no_mangle]
pub extern "C" fn closest_substring_center(x:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if x.is_null(){return -2}if len<4||len>44{return -1}let a=unsafe{std::slice::from_raw_parts(x,len)};let(nv,mv,lv,qv)=(a[0],a[1],a[2],a[3]);
 if nv<1||nv>4||mv<1||mv>10||lv<1||lv>8||lv>mv||(qv!=2&&qv!=3)||len!=4+(nv*mv) as usize{return -1}let(n,m,l,q)=(nv as usize,mv as usize,lv as usize,qv as usize);
 if a[4..].iter().any(|z|*z<0||*z>=qv){return -1}let mut total=1;for _ in 0..l{total*=q}let mut best=l+1;let mut bc=[0usize;8];
 for code in 0..total{let mut v=code;let mut cand=[0usize;8];for p in (0..l).rev(){cand[p]=v%q;v/=q}let mut radius=0;
  for row in 0..n{let mut rowbest=l+1;for st in 0..=m-l{let mut d=0;for j in 0..l{if cand[j] as i64!=a[4+row*m+st+j]{d+=1}}rowbest=rowbest.min(d)}radius=radius.max(rowbest)}if radius<best{best=radius;bc=cand}}
 let bytes=8*(l+1);if cap<bytes||out.is_null(){return -2}let dst=unsafe{std::slice::from_raw_parts_mut(out,bytes)};dst[..8].copy_from_slice(&(best as i64).to_le_bytes());for j in 0..l{dst[8*(j+1)..8*(j+2)].copy_from_slice(&(bc[j] as i64).to_le_bytes())}bytes as i64
}
