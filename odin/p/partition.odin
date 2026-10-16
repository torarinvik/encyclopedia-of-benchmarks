package partition
import "core:c"
solve :: proc(v:[^]i64,n,i:int,target,half:i64)->bool{if target==half do return true;if i>=n||target>half do return false;return solve(v,n,i+1,target+v[i],half)||solve(v,n,i+1,target,half)}
@(export)
partition :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>17||v[0]<0||v[0]>16||n!=c.size_t(v[0]+1) do return -1;count:=int(v[0]);sum:=i64(0);for i:=1;i<int(n);i+=1{x:=v[i];if x<0||x>1000 do return -1;sum+=x};if sum%2!=0 do return 0;return i64(solve(&v[1],count,0,0,sum/2))}

