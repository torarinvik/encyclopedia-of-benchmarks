fn solve(v &i64, n int, i int, target i64, half i64) bool { if target==half{return true};if i>=n||target>half{return false};unsafe{return solve(v,n,i+1,target+v[i],half)||solve(v,n,i+1,target,half)} }
@[export: 'partition']
pub fn partition(v &i64,n usize) i64 { unsafe { if v==nil||n<1||n>17||v[0]<0||v[0]>16||n!=usize(v[0]+1){return -1};count:=int(v[0]);mut sum:=i64(0);for i in 1..int(n){x:=v[i];if x<0||x>1000{return -1};sum+=x};if sum%2!=0{return 0};return i64(solve(&v[1],count,0,0,sum/2)) } }

