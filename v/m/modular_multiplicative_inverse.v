module modular_multiplicative_inverse
@[export: 'modular_multiplicative_inverse']
pub fn modular_multiplicative_inverse(v &i64,n usize)i64{unsafe{if v==nil||n!=2{return -1};a:=v[0];m:=v[1];if m<2||m>1000000||a<0||a>=m{return -1};mut r0:=a;mut r1:=m;mut s0:=i64(1);mut s1:=i64(0);for r1!=0{q:=r0/r1;t:=r0-q*r1;r0=r1;r1=t;u:=s0-q*s1;s0=s1;s1=u};if r0==1{return (s0%m+m)%m};return -1}}
