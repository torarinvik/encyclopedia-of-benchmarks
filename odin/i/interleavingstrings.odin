package interleavingstrings
import "core:c"
@(export)
interleavingstrings :: proc "c" (a:[^]i64,n:c.size_t)->i64{if a==nil||n<3 do return -1;m:=a[0];k:=a[1];q:=a[2];if m<0||m>32||k<0||k>32||q!=m+k||n!=c.size_t(3+m+k+q)do return -1;for i:=c.size_t(3);i<n;i+=1{if a[i]<0||a[i]>127 do return -1};ml:=int(m);kl:=int(k);s2:=3+ml;s3:=s2+kl;dp:[33][33]bool;dp[0][0]=true;for i:=0;i<=ml;i+=1{for j:=0;j<=kl;j+=1{if i>0&&dp[i-1][j]&&a[3+i-1]==a[s3+i+j-1]{dp[i][j]=true};if j>0&&dp[i][j-1]&&a[s2+j-1]==a[s3+i+j-1]{dp[i][j]=true}}};if dp[ml][kl]{return 1};return 0}
