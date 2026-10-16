module needleman_wunsch
const invalid=i64(-9223372036854775808)
@[export: 'needleman_wunsch']
pub fn needleman_wunsch(v &i64,n usize)i64{unsafe{
 if v==nil||n<5||n>261{return invalid};a,b,ms,mm,g:=v[0],v[1],v[2],v[3],v[4]
 if a<0||a>128||b<0||b>128||ms<0||ms>10||mm< -10||mm>0||g< -10||g>0||n!=usize(5+a+b){return invalid}
 for k in 0..int(a+b){if v[k+5]<65||v[k+5]>90{return invalid}}
 mut dp:=[129]i64{};for j in 0..int(b)+1{dp[j]=i64(j)*g}
 for i in 1..int(a)+1{mut diagonal:=dp[0];dp[0]=i64(i)*g;for j in 1..int(b)+1{old:=dp[j];mut score:=mm;if v[5+i-1]==v[5+int(a)+j-1]{score=ms};x,y,z:=diagonal+score,old+g,dp[j-1]+g;if x>=y&&x>=z{dp[j]=x}else if y>=z{dp[j]=y}else{dp[j]=z};diagonal=old}}return dp[int(b)]}}
