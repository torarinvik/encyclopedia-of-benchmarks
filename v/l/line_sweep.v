module line_sweep
@[export: 'line_sweep']
pub fn line_sweep(v &i64,n usize)f64{if n<1||n>17{return -1e300};count:=unsafe{v[0]};if count<0||count>8||n!=usize(1+2*count){return -1e300};if count==0{return 0};mut line:=[22]int{};for i in 0..int(count){s:=unsafe{v[1+2*i]};e:=unsafe{v[2+2*i]};if s<0||e<s||e>20{return -1e300};line[s]++;line[e+1]--};mut c:=0;mut m:=0;for d in line{c+=d;if c>m{m=c}};if m>1{return 1};return 0}
