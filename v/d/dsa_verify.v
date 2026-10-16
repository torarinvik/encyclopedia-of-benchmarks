module dsa_verify
fn is_prime(n i64) bool { if n < 2 { return false }; mut d := i64(2); for d*d <= n { if n%d == 0 { return false }; d++ }; return true }
fn mpow(a0 i64,e0 i64,m i64) i64 { mut a:=a0%m;mut e:=e0;mut r:=i64(1);for e>0 {if e&1 != 0 {r=r*a%m};a=a*a%m;e>>=1};return r }
@[export:'dsa_verify']
pub fn dsa_verify(v &i64,n usize)i64 { if unsafe{v==nil}||n<7||n>15{return -1};unsafe{p:=v[0];q:=v[1];g:=v[2];y:=v[3];r:=v[4];s:=v[5];ml:=v[6];if ml<0||ml>8||n!=usize(7+ml){return -1};if p<5||p>251||!is_prime(p)||q<2||q>=p||(p-1)%q!=0||!is_prime(q){return -1};if g<2||g>=p||mpow(g,q,p)!=1||y<1||y>=p||mpow(y,q,p)!=1||r<1||r>=q||s<1||s>=q{return -1};mut h:=i64(0);for i in 0..usize(ml){if v[7+i]<0||v[7+i]>255{return -1};h=(h*256+v[7+i])%q};w:=mpow(s,q-2,q);u1:=h*w%q;u2:=r*w%q;return i64(((mpow(g,u1,p)*mpow(y,u2,p))%p)%q==r) } }
