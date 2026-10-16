module elliptic_curve_key_exchange
struct Pt {
 inf bool
 x i64
 y i64
}
fn md(x i64,p i64)i64{r:=x%p;return if r<0 {r+p}else{r}}
fn prime(p i64) bool {
 if p < 2 { return false }
 mut d := i64(2)
 for d*d <= p { if p%d  ==  0 { return false }; d++ }
 return true
}
fn powm(x0 i64,n0 i64,p i64)i64{mut x:=md(x0,p);mut n:=n0;mut r:=i64(1);for n>0{if n & 1 != 0{r=r*x%p};x=x*x%p;n>>=1};return r}
fn add(p i64,a i64,u Pt,v Pt)Pt{if u.inf{return v};if v.inf{return u};if u.x == v.x && md(u.y+v.y,p) == 0{return Pt{inf:true}};s:=if u.x == v.x && u.y == v.y{md((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p)}else{md((v.y-u.y)*powm(v.x-u.x,p-2,p),p)};x:=md(s*s-u.x-v.x,p);return Pt{false,x,md(s*(u.x-x)-u.y,p)}}
fn mul(p i64,a i64,point Pt,scalar0 i64)Pt{mut q:=point;mut k:=scalar0;mut r:=Pt{inf:true};for k>0{if k & 1 != 0{r=add(p,a,r,q)};k>>=1;if k>0{q=add(p,a,q,q)}};return r}
fn put(mut o &u8,k int,v i64){mut b:=u64(v);for i in 0..8{unsafe{o[k+i]=u8(b&255)};b>>=8}}
@[export:'elliptic_curve_key_exchange']
pub fn elliptic_curve_key_exchange(v &i64,n usize,mut o &u8,cap usize)i64{if unsafe{v == nil} || n != 7{return -1};unsafe{p:=v[0];a:=v[1];b:=v[2];x:=v[3];y:=v[4];ka:=v[5];kb:=v[6];if p<5 || p>251 || !prime(p) || a<0 || a>=p || b<0 || b>=p || x<0 || x>=p || y<0 || y>=p || ka<1 || ka>1024 || kb<1 || kb>1024{return -1};if md(4*a*a*a+27*b*b,p) == 0 || md(y*y-x*x*x-a*x-b,p) != 0{return -1};if cap<48 || o == nil{return -2};g:=Pt{false,x,y};ap:=mul(p,a,g,ka);bp:=mul(p,a,g,kb);s:=mul(p,a,ap,kb);t:=mul(p,a,bp,ka);if s.inf != t.inf || (!s.inf && (s.x != t.x || s.y != t.y)){return -1};q := [ap, bp, s]; for i in 0..3 { put(mut o, i*16, if q[i].inf { -1 } else { q[i].x }); put(mut o, i*16+8, if q[i].inf { -1 } else { q[i].y }) };return 48}}
