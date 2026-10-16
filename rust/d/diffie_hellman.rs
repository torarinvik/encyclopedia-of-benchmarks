#[no_mangle]
pub extern "C" fn diffie_hellman(v: *const i64, n: usize) -> i64 {
    if v.is_null() || n != 4 { return -1; }
    let x=unsafe{std::slice::from_raw_parts(v,n)}; let (g,a,b,p)=(x[0],x[1],x[2],x[3]);
    if p<2||p>6_700_417||g<1||g>=p||a<1||a>=p||b<1||b>=p{return -1;}
    let mut d=2; while d*d<=p {if p%d==0{return -1;} d+=1;}
    fn mp(mut x:i64,mut e:i64,p:i64)->i64{let mut r=1%p;while e>0{if e&1==1{r=r*x%p;}x=x*x%p;e>>=1;}r}
    mp(mp(g,a,p),b,p)
}
