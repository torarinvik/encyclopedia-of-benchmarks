package kth_lexicographic_permutation
import "core:c"
@(export)
kth_lexicographic_permutation :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=2{return -1};k:=v[0];m:=v[1];if m<2||m>9||k<0{return -1};fact:=i64(1);for i:=i64(2);i<=m;i+=1{fact*=i};if k>=fact{return -1};a:[9]i64;for i:=i64(0);i<m;i+=1{a[i]=i};code:=m;for block:=m-1;block>=1;block-=1{f:=i64(1);for j:=i64(2);j<=block;j+=1{f*=j};idx:=k/f;k%=f;code=code*10+a[idx]+1;for j:=idx;j<block;j+=1{a[j]=a[j+1]}};return code*10+a[0]+1}
