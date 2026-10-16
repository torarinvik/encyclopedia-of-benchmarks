module interleavingstrings
@[export:'interleavingstrings']
pub fn interleavingstrings(a &i64,n usize)i64{if unsafe{a==nil}||n<3{return -1};unsafe{m:=a[0];k:=a[1];q:=a[2];if m<0||m>32||k<0||k>32||q!=m+k||n!=usize(3+m+k+q){return -1};for i in 3..n{if a[i]<0||a[i]>127{return -1}}ml:=int(m);kl:=int(k);s2:=3+ml;s3:=s2+kl;mut dp:=[33][33]bool{};dp[0][0]=true;for i in 0..ml+1{for j in 0..kl+1{if i>0&&dp[i-1][j]&&a[3+i-1]==a[s3+i+j-1]{dp[i][j]=true};if j>0&&dp[i][j-1]&&a[s2+j-1]==a[s3+i+j-1]{dp[i][j]=true}}};return if dp[ml][kl]{1}else{0}}}
