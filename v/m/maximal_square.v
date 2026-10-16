module maximal_square
@[export: 'maximal_square']
pub fn maximal_square(a &i64,length usize)i64{
 if unsafe{a==nil}||length<3||length>258{return -1}
 rowsval:=unsafe{a[0]};colsval:=unsafe{a[1]};if rowsval<1||rowsval>16||colsval<1||colsval>16||length!=usize(rowsval*colsval+2){return -1}
 rows:=int(rowsval);cols:=int(colsval);mut dp:=[16]int{};mut best:=0
 for i in 0..rows*cols{x:=unsafe{a[i+2]};if x!=0&&x!=1{return -1}}
 for r in 0..rows{mut diag:=0;for c in 0..cols{above:=dp[c];if unsafe{a[r*cols+c+2]}==1{if r==0||c==0{dp[c]=1}else{dp[c]=min(diag,min(dp[c],dp[c-1]))+1};best=max(best,dp[c])}else{dp[c]=0};diag=above}}
 return i64(best*best)
}
