#[derive(Clone,Copy)] struct Pt{inf:bool,x:i64,y:i64}
fn md(x:i64,p:i64)->i64{let r=x%p;if r<0{r+p}else{r}}
fn prime(p:i64)->bool{if p<2{return false}let mut d=2;while d*d<=p{if p%d==0{return false}d+=1}true}
fn powm(mut x:i64,mut n:i64,p:i64)->i64{let mut r=1;x=md(x,p);while n>0{if n&1!=0{r=r*x%p}x=x*x%p;n>>=1}r}
fn add(p:i64,a:i64,u:Pt,v:Pt)->Pt{if u.inf{return v}if v.inf{return u}if u.x==v.x&&md(u.y+v.y,p)==0{return Pt{inf:true,x:0,y:0}}let s=if u.x==v.x&&u.y==v.y{md((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p)}else{md((v.y-u.y)*powm(v.x-u.x,p-2,p),p)};let x=md(s*s-u.x-v.x,p);Pt{inf:false,x,y:md(s*(u.x-x)-u.y,p)}}
fn mul(p:i64,a:i64,mut q:Pt,mut k:i64)->Pt{let mut r=Pt{inf:true,x:0,y:0};while k>0{if k&1!=0{r=add(p,a,r,q)}k>>=1;if k>0{q=add(p,a,q,q)}}r}
unsafe fn put(o:*mut u8,k:usize,v:i64){let b=v as u64;for i in 0..8{*o.add(k+i)=(b>>(8*i)) as u8}}
#[no_mangle] pub unsafe extern "C" fn elliptic_curve_key_exchange(v:*const i64,n:usize,o:*mut u8,cap:usize)->i64{if v.is_null()||n!=7{return -1}let p=*v;let a=*v.add(1);let b=*v.add(2);let x=*v.add(3);let y=*v.add(4);let ka=*v.add(5);let kb=*v.add(6);if p<5||p>251||!prime(p)||a<0||a>=p||b<0||b>=p||x<0||x>=p||y<0||y>=p||ka<1||ka>1024||kb<1||kb>1024{return -1}if md(4*a*a*a+27*b*b,p)==0||md(y*y-x*x*x-a*x-b,p)!=0{return -1}if cap<48||o.is_null(){return -2}let g=Pt{inf:false,x,y};let ap=mul(p,a,g,ka);let bp=mul(p,a,g,kb);let s=mul(p,a,ap,kb);let t=mul(p,a,bp,ka);if s.inf!=t.inf||(!s.inf&&(s.x!=t.x||s.y!=t.y)){return -1}for (i,q) in [ap,bp,s].iter().enumerate(){put(o,i*16,if q.inf{-1}else{q.x});put(o,i*16+8,if q.inf{-1}else{q.y})}48}
