module ic_555_timer
@[export: 'ic_555_timer']
pub fn ic_555_timer(v &i64,n usize) f64{if n!=4{return -1.0e300};m:=unsafe{v[0]};a:=unsafe{v[1]};b:=unsafe{v[2]};c:=unsafe{v[3]};if (m!=0&&m!=1)||a<1||a>1000000||b<1||b>1000000||(m==0&&(c<1||c>1000000))||(m==1&&(c<0||c>1000000)){return -1.0e300};if m==0{return (1.44/(f64(a+2*b)*f64(c)))*1e6};return (f64(a+b)/f64(a+2*b))*100.0}
