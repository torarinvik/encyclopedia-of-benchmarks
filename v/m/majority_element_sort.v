module majority_element_sort
@[export: 'majority_element_sort']
pub fn majority_element_sort(v &i64,n usize)i64{unsafe{if v==nil||n<2||n>128{return -1};mut a:=[128]i32{};for i in 0..n{if v[i] < -2147483648||v[i] > 2147483647{return -1};a[i]=i32(v[i])};for i in 1..n{x:=a[i];mut j:=i;for j>0&&a[j-1]>x{a[j]=a[j-1];j--};a[j]=x};mut run:=1;for i in 1..n{if a[i]==a[i-1]{run++}else{run=1};if run>n/2{return i64(a[i])}};return -1}}
