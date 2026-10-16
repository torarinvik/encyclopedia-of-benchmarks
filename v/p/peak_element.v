module peak_element
fn peak(a &i64,lo int,hi int,n int)i64{unsafe{mid:=lo+(hi-lo)/2;if (mid==0||a[mid-1]<=a[mid])&&(mid==n-1||a[mid+1]<=a[mid]){return i64(mid)};if mid>0&&a[mid-1]>a[mid]{return peak(a,lo,mid-1,n)};return peak(a,mid+1,hi,n)}}
@[export: 'peak_element']
pub fn peak_element(v &i64,n usize)i64{unsafe{if v==nil||n<2||n>129||v[0]<1||v[0]>128||n!=usize(v[0]+1){return -1};count:=int(v[0]);for i in 0..count{if v[i+1] < -2147483648||v[i+1] > 2147483647{return -1}};return peak(&v[1],0,count-1,count)}}
