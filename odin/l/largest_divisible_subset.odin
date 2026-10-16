package largest_divisible_subset
import "core:c"
@(export)
largest_divisible_subset :: proc "c" (v:[^]i64,n:c.size_t)->i64{if(v==nil&&n!=0)||n>64{return -1};a:[64]i64;d:[64]i64;for i in 0..<n{if v[i]<1||v[i]>50000{return -1};a[i]=v[i]};for i in 1..<n{x:=a[i];j:=i;for j>0&&a[j-1]>x{a[j]=a[j-1];j-=1};a[j]=x};best:=i64(0);for i in 0..<n{d[i]=1;for j in 0..<i{if a[i]%a[j]==0&&d[j]+1>d[i]{d[i]=d[j]+1}};if d[i]>best{best=d[i]}};return best}
