package majority_element_sort
import "core:c"
@(export)
majority_element_sort :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>128 do return -1;a:[128]i32;for i:=0;i<int(n);i+=1{if v[i] < -2147483648||v[i] > 2147483647 do return -1;a[i]=i32(v[i])};for i:=1;i<int(n);i+=1{x:=a[i];j:=i;for j>0&&a[j-1]>x{a[j]=a[j-1];j-=1};a[j]=x};run:=1;for i:=1;i<int(n);i+=1{if a[i]==a[i-1]{run+=1}else{run=1};if run>int(n)/2 do return i64(a[i])};return -1}
