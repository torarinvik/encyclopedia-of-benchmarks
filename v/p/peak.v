fn find_peak(a &i64,lo int,hi int) i64 { unsafe { m:=(hi-lo)/2;l:=a[lo+m-1];c:=a[lo+m];r:=a[lo+m+1];if c>l&&c>r{return c};if l<r{start:=m;if m==2{start--};return find_peak(&a[start],0,hi-lo-start)};end:=m;if m==2{end++};return find_peak(a,0,end) } }
@[export: 'peak']
pub fn peak(v &i64,n usize) i64 { unsafe { if v==nil||n<4||n>65||v[0]<3||v[0]>64||n!=usize(v[0]+1){return -1};len:=int(v[0]);mut p:=1;for i in 0..len{if v[i+1]<-1000000||v[i+1]>1000000{return -1}};for p<len-1&&v[p+1]>v[p]{p++};if p==1||p>=len-1{return -1};for i in p..len-1{if v[i+2]>=v[i+1]{return -1}};return find_peak(&v[1],0,len) } }

