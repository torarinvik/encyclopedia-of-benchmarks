module long_division
@[export: 'long_division']
pub fn long_division(v &i64,n usize)i64{if n!=2{return -1};a0:=unsafe{v[0]};b0:=unsafe{v[1]};if a0< -1000000||a0>1000000||b0< -10000||b0>10000{return -1};if b0==0{return 0};neg:=(a0<0)!=(b0<0);mut a:=a0;mut b:=b0;if a<0{a=-a};if b<0{b=-b};mut ds:=[16]i64{};mut len:=0;if a==0{len=1};for a>0{ds[len]=a%10;a/=10;len++};mut rem:=i64(0);mut q:=i64(0);for len>0{len--;rem=rem*10+ds[len];mut d:=i64(0);for rem>=b{rem-=b;d++};q=q*10+d};if neg{return -q};return q}
