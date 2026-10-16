#[no_mangle]
pub extern "C" fn uncommon_words(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<1||n>1089{return -1;}let v=unsafe{std::slice::from_raw_parts(v,n)};if !(0..=64).contains(&v[0]){return -1;}
 let mut words=[[0u8;16];64];let mut lens=[0usize;64];let mut counts=[0usize;64];let mut d=0usize;let mut p=1usize;
 for _ in 0..v[0] {if p>=n||!(1..=16).contains(&v[p]){return -1;}let l=v[p] as usize;p+=1;if l>n-p{return -1;}for &c in &v[p..p+l]{if !(97..=122).contains(&c){return -1;}}let mut id=0;while id<d&&!(lens[id]==l&&words[id][..l].iter().zip(&v[p..p+l]).all(|(&a,&b)|i64::from(a)==b)){id+=1;}if id==d{lens[d]=l;for j in 0..l{words[d][j]=v[p+j] as u8;}d+=1;}counts[id]+=1;p+=l;}
 if p!=n{return -1;}let mut temp=[0u8;1089];let mut at=0;for id in 0..d{if counts[id]==1{temp[at..at+lens[id]].copy_from_slice(&words[id][..lens[id]]);at+=lens[id];temp[at]=b'\n';at+=1;}}if at>0{at-=1;}temp[at]=0;at+=1;if out.is_null()||cap<at{return -2;}unsafe{std::ptr::copy_nonoverlapping(temp.as_ptr(),out,at);}at as i64
}
