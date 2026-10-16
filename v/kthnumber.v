module kthnumber
fn part(mut a []i64,lo int,hi int)int{pivot:=a[hi];mut i:=lo;for j:=lo;j<hi;j++{if a[j]<pivot{a[i],a[j]=a[j],a[i];i++}};a[i],a[hi]=a[hi],a[i];return i}
@[export: 'kthnumber']
pub fn kthnumber(v &i64,n usize)i64{if n<4||n>19{return -1};count:=unsafe{v[0]};mode:=unsafe{v[1]};k:=unsafe{v[2]};if count<1||count>16||n!=usize(count+3)||(mode!=1&&mode!=2)||k<1||k>count{return -1};mut a:=[]i64{len:int(count)};for i in 0..int(count){a[i]=unsafe{v[i+3]};if a[i]<-10000||a[i]>10000{return -1}};target:=int(k-1);if mode==2{target=int(count-k)};mut lo:=0;mut hi:=int(count)-1;for lo<=hi{q:=part(mut a,lo,hi);if q==target{return a[q]};if q<target{lo=q+1}else{hi=q-1}};return -1}
