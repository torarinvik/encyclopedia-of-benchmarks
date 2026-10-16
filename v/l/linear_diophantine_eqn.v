module linear_diophantine_eqn
fn gcdv(a0 i64,b0 i64)i64{mut a:=a0;mut b:=b0;if a<0{a=-a};if b<0{b=-b};for b!=0{r:=a%b;a=b;b=r};return a}
@[export: 'linear_diophantine_eqn']
pub fn linear_diophantine_eqn(v &i64,n usize)i64{if n!=3{return -1};a:=unsafe{v[0]};b:=unsafe{v[1]};c:=unsafe{v[2]};if a< -100000||a>100000||b==0||b< -100000||b>100000||c< -1000000||c>1000000{return -1};if c%gcdv(a,b)==0{return 1};return 0}
