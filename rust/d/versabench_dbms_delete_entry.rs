const MAX_OUTPUT_WORDS:usize=181;
fn valid(b:&[i64;8])->bool{(0..4).all(|d|(-8..=8).contains(&b[d])&&(-8..=8).contains(&b[4+d])&&b[d]<b[4+d])}
fn hit(b:&[i64;8],q:&[i64;8])->bool{(0..4).all(|d|q[d]<=b[4+d]&&b[d]<=q[4+d])}
fn union(bs:&[[i64;8]])->[i64;8]{let mut out=bs[0];for b in &bs[1..]{for d in 0..4{out[d]=out[d].min(b[d]);out[4+d]=out[4+d].max(b[4+d]);}}out}
fn put(out:*mut u8,w:usize,x:i64){for b in 0..8{unsafe{*out.add(w*8+b)=((x as u64)>>(8*b)) as u8;}}}
#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_delete_entry(raw:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if raw.is_null()||n<10||n>190{return -1}let v=unsafe{std::slice::from_raw_parts(raw,n)};let ncv=v[0];if !(1..=4).contains(&ncv){return -1}let nc=ncv as usize;let mut q=[0_i64;8];q.copy_from_slice(&v[1..9]);if !valid(&q){return -1}
 let mut boxes=[[[0_i64;8];4];4];let mut ids=[[0_i64;4];4];let mut mbrs=[[0_i64;8];4];let mut counts=[0_usize;4];let mut seen=[false;32];let mut p=9;
 for c in 0..nc{if p+9>n{return -1}let rv=v[p];p+=1;if !(1..=4).contains(&rv)||p+8+rv as usize*9>n{return -1}counts[c]=rv as usize;mbrs[c].copy_from_slice(&v[p..p+8]);p+=8;if !valid(&mbrs[c]){return -1}for r in 0..counts[c]{boxes[c][r].copy_from_slice(&v[p..p+8]);p+=8;ids[c][r]=v[p];p+=1;if !valid(&boxes[c][r])||!(0..32).contains(&ids[c][r])||seen[ids[c][r] as usize]{return -1}seen[ids[c][r] as usize]=true;}if union(&boxes[c][..counts[c]])!=mbrs[c]{return -1}}
 if p!=n{return -1}let mut kept=[[[0_i64;8];4];4];let mut kid=[[0_i64;4];4];let mut kmbr=[[0_i64;8];4];let mut kc=[0_usize;4];let mut rem=0;
 for c in 0..nc{let mut k=0;for r in 0..counts[c]{if hit(&mbrs[c],&q)&&hit(&boxes[c][r],&q){continue}kept[c][k]=boxes[c][r];kid[c][k]=ids[c][r];k+=1}if k>0{kc[rem]=k;for r in 0..k{kept[rem][r]=kept[c][r];kid[rem][r]=kid[c][r]}kmbr[rem]=union(&kept[rem][..k]);rem+=1}}
 let mut w=[0_i64;MAX_OUTPUT_WORDS];let mut x=0;w[x]=rem as i64;x+=1;for c in 0..rem{w[x]=kc[c] as i64;x+=1;for d in 0..8{w[x]=kmbr[c][d];x+=1}for r in 0..kc[c]{for d in 0..8{w[x]=kept[c][r][d];x+=1}w[x]=kid[c][r];x+=1}}
 let bytes=x*8;if out.is_null()||cap<bytes{return -2}for i in 0..x{put(out,i,w[i])}bytes as i64
}
