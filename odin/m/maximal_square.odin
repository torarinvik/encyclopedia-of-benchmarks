package maximal_square
import "core:c"
@(export)
maximal_square :: proc "c" (a:[^]i64,length:c.size_t)->i64 {
 if a==nil||length<3||length>258||a[0]<1||a[0]>16||a[1]<1||a[1]>16||int(length)!=int(a[0]*a[1])+2 do return -1
 rows:=int(a[0]);cols:=int(a[1]);dp:[16]int;best:=0
 for i:=0;i<rows*cols;i+=1 {if a[i+2]!=0&&a[i+2]!=1 do return -1}
 for r:=0;r<rows;r+=1 {diag:=0;for col:=0;col<cols;col+=1 {above:=dp[col];if a[r*cols+col+2]==1 {if r==0||col==0 do dp[col]=1 else {m:=diag;if dp[col]<m do m=dp[col];if dp[col-1]<m do m=dp[col-1];dp[col]=m+1};if dp[col]>best do best=dp[col]}else{dp[col]=0};diag=above}}
 return i64(best*best)
}
