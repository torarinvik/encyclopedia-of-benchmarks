package kth_smallest_heap
import "core:c"
down :: proc(h:[]i64,i0:int){i:=i0;for{l:=2*i+1;r:=l+1;m:=i;if l<len(h)&&h[l]>h[m]{m=l};if r<len(h)&&h[r]>h[m]{m=r};if m==i{break};h[i],h[m]=h[m],h[i];i=m}}
@(export)
kth_smallest_heap :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>65{return -1};k:=v[0];if k<1||k>=i64(n){return -1};h:=[dynamic]i64{};for i:=i64(0);i<k;i+=1{x:=v[i+1];if x< -100000||x>100000{return -1};append(&h,x)};make_heap(h[:]);for i:=k+1;i<i64(n);i+=1{x:=v[i];if x< -100000||x>100000{return -1};if x<=h[0]{h[0]=x;down(h[:],0)}};return h[0]}
make_heap :: proc(h:[]i64){for i:=len(h)/2-1;i>=0;i-=1{down(h,i)}}
