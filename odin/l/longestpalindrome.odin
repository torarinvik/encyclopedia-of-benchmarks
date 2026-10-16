package longestpalindrome
import "core:c"
@(export)
longestpalindrome :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65 do return -1;count:=v[0];if count<0||count>64||n!=c.size_t(count+1) do return -1;a:[64]i64;m:=0;for i:=0;i<int(count);i+=1{x:=v[1+c.size_t(i)];if x<32||x>126||x==35 do return -1;if x!=32{a[m]=x;m+=1}};t:[129]i64;z:=2*m+1;for i:=0;i<z;i+=1{if i%2==0{t[i]= -1}else{t[i]=a[i/2]}};p:[129]int;center:=0;right:=0;best:=0;for i:=0;i<z;i+=1{if i<right{p[i]=min(p[2*center-i],right-i)};for i>=p[i]+1&&i+p[i]+1<z&&t[i-p[i]-1]==t[i+p[i]+1]{p[i]+=1};best=max(best,p[i]);if i+p[i]>right{center=i;right=i+p[i]}};return i64(best)}
