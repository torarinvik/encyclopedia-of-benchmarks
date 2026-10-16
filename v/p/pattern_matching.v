@[export: 'pattern_matching']
pub fn pattern_matching(v &i64,n usize)i64{unsafe{if v==nil||n<3||n>130||v[0]<0||v[0]>64{return -1};t:=int(v[0]);pp:=t+1;if int(n)<pp+1||v[pp]<1||v[pp]>64{return -1};p:=int(v[pp]);if int(n)!=pp+p+1||p>t{return -1};for i in 1..pp{if v[i]<0||v[i]>127{return -1}};for i in pp+1..int(n){if v[i]<0||v[i]>127{return -1}};for i:=0;i<=t-p;i++{mut j:=0;for j<p&&v[i+1+j]==v[pp+1+j]{j++};if j==p{return i64(i)}};return -1}}

