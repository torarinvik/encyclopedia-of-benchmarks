package elliptic_curve_key_exchange
import "core:c"
Pt :: struct { inf: bool, x, y: i64 }
md :: proc "contextless" (x,p:i64)->i64 { r:=x%p; if r<0 { return r+p }; return r }
prime :: proc "contextless" (p:i64)->bool { if p<2 { return false }; for d:i64=2; d*d<=p; d+=1 { if p%d==0 { return false } }; return true }
powm :: proc "contextless" (x0,n0,p:i64)->i64 { x:=md(x0,p); n:=n0; r:i64=1; for n>0 { if n&1!=0 { r=r*x%p }; x=x*x%p; n>>=1 }; return r }
inf_point :: proc "contextless" ()->Pt { return Pt{true,0,0} }
add :: proc "contextless" (p,a:i64,u,v:Pt)->Pt { if u.inf { return v }; if v.inf { return u }; if u.x==v.x && md(u.y+v.y,p)==0 { return inf_point() }; s:i64=0; if u.x==v.x && u.y==v.y { s=md((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p) } else { s=md((v.y-u.y)*powm(v.x-u.x,p-2,p),p) }; x:=md(s*s-u.x-v.x,p); return Pt{false,x,md(s*(u.x-x)-u.y,p)} }
mul :: proc "contextless" (p,a:i64,point:Pt,k0:i64)->Pt { q:=point; k:=k0; r:=inf_point(); for k>0 { if k&1!=0 { r=add(p,a,r,q) }; k>>=1; if k>0 { q=add(p,a,q,q) } }; return r }
put :: proc "contextless" (o:[^]u8,k:c.size_t,v:i64) { b:=u64(v); for i:c.size_t=0; i<8; i+=1 { o[k+i]=u8((b>>(i*8))&255) } }
@(export)
elliptic_curve_key_exchange :: proc "c" (v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64 {
 if v==nil || n!=7 { return -1 }; p:=v[0]; a:=v[1]; b:=v[2]; x:=v[3]; y:=v[4]; ka:=v[5]; kb:=v[6]
 if p<5||p>251||!prime(p)||a<0||a>=p||b<0||b>=p||x<0||x>=p||y<0||y>=p||ka<1||ka>1024||kb<1||kb>1024 { return -1 }
 if md(4*a*a*a+27*b*b,p)==0||md(y*y-x*x*x-a*x-b,p)!=0 { return -1 }; if cap<48||o==nil { return -2 }
 g:=Pt{false,x,y}; ap:=mul(p,a,g,ka); bp:=mul(p,a,g,kb); s:=mul(p,a,ap,kb); t:=mul(p,a,bp,ka)
 if s.inf!=t.inf||(!s.inf&&(s.x!=t.x||s.y!=t.y)) { return -1 }
 q:=[3]Pt{ap,bp,s}; for i:c.size_t=0;i<3;i+=1 { px:=q[i].x; py:=q[i].y; if q[i].inf { px=-1; py=-1 }; put(o,i*16,px); put(o,i*16+8,py) }; return 48
}
