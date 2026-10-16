module permutation_calculation
fn factorial(n i64)i64{mut x:=i64(1);for i:=i64(1);i<=n;i++{x*=i};return x}
@[export: 'permutation_calculation']
pub fn permutation_calculation(v &i64,n usize)i64{unsafe{if v==nil||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0]{return -1};return factorial(v[0])/factorial(v[0]-v[1])}}
