module largest_divisible_subset
@[export: 'largest_divisible_subset']
pub fn largest_divisible_subset(v &i64,n usize)i64{if n>64{return -1};mut a:=[]i64{len:n};for i in 0..n{if unsafe{v[i]}<1||unsafe{v[i]}>50000{return -1};a[i]=unsafe{v[i]}};a.sort();mut d:=[]i64{len:n,init:1};mut best:=i64(0);for i in 0..n{for j in 0..i{if a[i]%a[j]==0&&d[j]+1>d[i]{d[i]=d[j]+1}};if d[i]>best{best=d[i]}};return best}
