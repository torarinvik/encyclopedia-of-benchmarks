package needleman_wunsch
import "core:c"
INVALID :: i64 = -9223372036854775808
@(export)
needleman_wunsch :: proc "c" (v: [^]i64,n: c.size_t)->i64{
	if v==nil||n<5||n>261 do return INVALID
	a,b,match_score,mismatch,gap:=v[0],v[1],v[2],v[3],v[4]
	if a<0||a>128||b<0||b>128||match_score<0||match_score>10||mismatch< -10||mismatch>0||gap< -10||gap>0||n!=c.size_t(5+a+b) do return INVALID
	for i:=0;i<int(a+b);i+=1{if v[i+5]<65||v[i+5]>90 do return INVALID}
	dp:[129]i64
	for j:=0;j<=int(b);j+=1{dp[j]=i64(j)*gap}
	for i:=1;i<=int(a);i+=1{diagonal:=dp[0];dp[0]=i64(i)*gap;for j:=1;j<=int(b);j+=1{old:=dp[j];score:=mismatch;if v[5+i-1]==v[5+int(a)+j-1]{score=match_score};x,y,z:=diagonal+score,old+gap,dp[j-1]+gap;if x>=y&&x>=z{dp[j]=x}else if y>=z{dp[j]=y}else{dp[j]=z};diagonal=old}}
	return dp[int(b)]
}
