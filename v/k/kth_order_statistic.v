module kth_order_statistic
fn qs(a []i64,k int)i64{if a.len==1{return a[0]};p:=a[0];mut small:=[]i64{};mut big:=[]i64{};for i in 1..<a.len{if a[i]<p{small<<a[i]}else if a[i]>p{big<<a[i]}};if k==small.len+1{return p};if k<=small.len{return qs(small,k)};return qs(big,k-small.len-1)}
@[export: 'kth_order_statistic']
pub fn kth_order_statistic(v &i64,n usize)i64{if n<2||n>65{return -1};k:=unsafe{v[0]};if k<1||k>=i64(n){return -1};mut a:=[]i64{};for i in 1..n{z:=unsafe{v[i]};if z< -10000||z>10000{return -1};for j in 1..i{if z==unsafe{v[j]}{return -1}};a<<z};return qs(a,k)}
