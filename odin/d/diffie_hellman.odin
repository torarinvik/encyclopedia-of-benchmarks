package diffie_hellman
import "core:c"
@(export)
diffie_hellman :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 if v==nil||n!=4 do return -1
 g,a,b,p:=v[0],v[1],v[2],v[3]
 if p<2||p>6700417||g<1||g>=p||a<1||a>=p||b<1||b>=p{return -1}
 d:i64=2;for d*d<=p {if p%d==0{return -1};d+=1}
 x,e,r:=g,a,i64(1);for e>0 {if e&1==1{r=r*x%p};x=x*x%p;e>>=1}
 x,e,r=r,b,1;for e>0 {if e&1==1{r=r*x%p};x=x*x%p;e>>=1};return r
}
