/// Bounded exact closest-string center by lexicographic exhaustive search.
#[no_mangle]
pub extern "C" fn closest_string_center(x:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if x.is_null(){return -2}if len<3||len>51{return -1}let a=unsafe{std::slice::from_raw_parts(x,len)};let(nv,mv,qv)=(a[0],a[1],a[2]);
 if nv<1||nv>6||mv<1||mv>8||(qv!=2&&qv!=3)||len!=3+(nv*mv) as usize{return -1}let(n,m,q)=(nv as usize,mv as usize,qv as usize);
 if a[3..].iter().any(|v|*v<0||*v>=qv){return -1}let mut total=1usize;for _ in 0..m{total*=q}let mut best=m+1;let mut bestc=[0usize;8];
 for code in 0..total{let mut v=code;let mut cand=[0usize;8];for p in (0..m).rev(){cand[p]=v%q;v/=q}let mut radius=0;
  for row in 0..n{let mut d=0;for col in 0..m{if cand[col] as i64!=a[3+row*m+col]{d+=1}}radius=radius.max(d)}if radius<best{best=radius;bestc=cand}}
 let bytes=8*(m+1);if cap<bytes||out.is_null(){return -2}let dest=unsafe{std::slice::from_raw_parts_mut(out,bytes)};dest[..8].copy_from_slice(&(best as i64).to_le_bytes());for j in 0..m{dest[8*(j+1)..8*(j+2)].copy_from_slice(&(bestc[j] as i64).to_le_bytes())}bytes as i64
}
