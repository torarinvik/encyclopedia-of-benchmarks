fn is_prime(n:i64)->bool{if n<2{return false}let mut d=2;while d*d<=n{if n%d==0{return false}d+=1}true}
fn mpow(mut a:i64,mut e:i64,m:i64)->i64{let mut r=1;a%=m;while e>0{if e&1!=0{r=r*a%m}a=a*a%m;e>>=1}r}
#[no_mangle]
pub unsafe extern "C" fn dsa_verify(v:*const i64,n:usize)->i64{if v.is_null()||n<7||n>15{return -1}let a=std::slice::from_raw_parts(v,n);let(p,q,g,y,r,s,ml)=(a[0],a[1],a[2],a[3],a[4],a[5],a[6]);if ml<0||ml>8||n!=7+ml as usize{return -1}if p<5||p>251||!is_prime(p)||q<2||q>=p||(p-1)%q!=0||!is_prime(q){return -1}if g<2||g>=p||mpow(g,q,p)!=1||y<1||y>=p||mpow(y,q,p)!=1||r<1||r>=q||s<1||s>=q{return -1}let mut h=0;for &b in &a[7..]{if b<0||b>255{return -1}h=(h*256+b)%q}let w=mpow(s,q-2,q);let u1=h*w%q;let u2=r*w%q;(((mpow(g,u1,p)*mpow(y,u2,p))%p)%q==r) as i64}
