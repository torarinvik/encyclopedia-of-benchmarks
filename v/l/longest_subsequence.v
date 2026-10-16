module longest_subsequence
fn solve(a []i64)[]i64{if a.len<=1{return a.clone()};pivot:=a[0];mut best:=[]i64{};mut i:=1;for i<a.len{if a[i]<pivot{mut tail:=[]i64{};for j in i+1..a.len{if a[j]>=a[i]{tail<<a[j]}};cand:= [a[i]] + solve(tail);if cand.len>best.len{best=cand;i=best.len}};i++};mut tail:=[]i64{};for i in 1..a.len{if a[i]>=pivot{tail<<a[i]}};cand:=[pivot]+solve(tail);if cand.len>best.len{best=cand};return best}
@[export: 'longest_subsequence']
pub fn longest_subsequence(v &i64,n usize)i64{if n<2||n>11{return -1};k:=unsafe{v[0]};if k<1||k>10||n!=usize(k+1){return -1};mut a:=[]i64{len:int(k)};for i in 0..int(k){a[i]=unsafe{v[i+1]};if a[i]<-10||a[i]>10{return -1}};seq:=solve(a);mut r:=i64(seq.len);for x in seq{r=r*21+x+10};return r}
