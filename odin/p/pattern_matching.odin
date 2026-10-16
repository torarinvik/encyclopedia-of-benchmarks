package pattern_matching
import "core:c"
@(export)
pattern_matching :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<3||n>130||v[0]<0||v[0]>64 do return -1;t:=int(v[0]);pp:=t+1;if int(n)<pp+1||v[pp]<1||v[pp]>64 do return -1;p:=int(v[pp]);if int(n)!=pp+p+1||p>t do return -1;for i:=1;i<pp;i+=1{if v[i]<0||v[i]>127 do return -1};for i:=pp+1;i<int(n);i+=1{if v[i]<0||v[i]>127 do return -1};for i:=0;i<=t-p;i+=1{j:=0;for j<p&&v[i+1+j]==v[pp+1+j]{j+=1};if j==p do return i64(i)};return -1}

