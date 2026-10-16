module diffie_hellman
@[export: 'diffie_hellman']
pub fn diffie_hellman(v &i64, n usize) i64 {
 if n!=4{return -1};g:=unsafe{v[0]};a:=unsafe{v[1]};b:=unsafe{v[2]};p:=unsafe{v[3]}
 if p<2||p>6700417||g<1||g>=p||a<1||a>=p||b<1||b>=p{return -1}
 mut d:=i64(2);for d*d<=p {if p%d==0{return -1};d++}
 mut x:=g;mut e:=a;mut r:=i64(1);for e>0 {if e&1!=0 {r=r*x%p};x=x*x%p;e>>=1}
 x=r;e=b;r=1;for e>0 {if e&1!=0 {r=r*x%p};x=x*x%p;e>>=1};return r
}
