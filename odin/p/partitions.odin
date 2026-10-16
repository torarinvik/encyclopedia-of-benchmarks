package partitions
import "core:c"
MAX_N :: 100
STRIDE :: 101
count_parts :: proc(n,k:int,memo:[^]i64)->i64{if (n==0&&k==0)||(n>0&&k==1)||n==k do return 1;if k==0||k>n do return 0;idx:=n*STRIDE+k;if memo[idx]>=0 do return memo[idx];memo[idx]=count_parts(n-1,k-1,memo)+count_parts(n-k,k,memo);return memo[idx]}
@(export)
partitions :: proc "c" (n:i64)->i64{if n<0||n>MAX_N do return -9223372036854775807-1;memo:[STRIDE*STRIDE]i64;for i in 0..<STRIDE*STRIDE do memo[i]=-1;total:=i64(0);for k:=1;k<=int(n);k+=1{total+=count_parts(int(n),k,&memo[0])};if n==0 do return 1;return total}
