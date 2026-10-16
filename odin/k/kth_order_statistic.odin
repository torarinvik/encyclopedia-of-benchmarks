package kth_order_statistic
import "core:c"
select_k :: proc(a:[]i64,k:i64)->i64{if len(a)==1{return a[0]};p:=a[0];small:=[dynamic]i64{};big:=[dynamic]i64{};for i in 1..<len(a){if a[i]<p{append(&small,a[i])}else if a[i]>p{append(&big,a[i])}};if k==i64(len(small))+1{return p};if k<=i64(len(small)){return select_k(small[:],k)};return select_k(big[:],k-i64(len(small))-1)}
@(export)
kth_order_statistic :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>65{return -1};k:=v[0];if k<1||k>=i64(n){return -1};a:=[dynamic]i64{};for i in 1..<n{if v[i]<-10000||v[i]>10000{return -1};for j in 1..<i{if v[i]==v[j]{return -1}};append(&a,v[i])};return select_k(a[:],k)}
