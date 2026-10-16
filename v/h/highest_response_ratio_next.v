module highest_response_ratio_next
@[export: 'highest_response_ratio_next']
pub fn highest_response_ratio_next(v &i64,n usize,out &u8,capacity usize)i64{
 if unsafe{v==nil}||n<3||n>129{return -1};count:=unsafe{v[0]};if count<1||count>64||n!=1+2*int(count){return -1};mut a:=[64]i64{};mut b:=[64]i64{};mut tat:=[64]i64{};mut done:=[64]bool{}
 for i in 0..int(count){a[i]=unsafe{v[1+2*i]};b[i]=unsafe{v[2+2*i]};if a[i]<0||a[i]>100000||b[i]<1||b[i]>1000{return -1}};for i in 1..int(count){mut j:=i;for j>0&&a[j]<a[j-1]{a[j],a[j-1]=a[j-1],a[j];b[j],b[j-1]=b[j-1],b[j];j--}}
 if int(count)*8>capacity||(count>0&&unsafe{out==nil}){return -2};mut now:=i64(0);mut finished:=0
 for finished<int(count){mut best:=-1;mut best_num:=i64(0);for i in 0..int(count){if !done[i]&&a[i]<=now{cand:=now-a[i]+b[i];if best<0||cand*b[best]>best_num*b[i]{best=i;best_num=cand}}};if best<0{for i in 0..int(count){if !done[i]&&(best<0||a[i]<a[best]){best=i}};now=a[best]}else{tat[best]=now+b[best]-a[best];now+=b[best];done[best]=true;finished++}}
 for i in 0..int(count){bits:=u64(tat[i]);for j in 0..8{unsafe{out[i*8+j]=u8(bits>>(j*8))}}};return count*8
}
