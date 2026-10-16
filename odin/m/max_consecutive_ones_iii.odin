package max_consecutive_ones_iii
import "core:c"
@(export)
max_consecutive_ones_iii :: proc "c" (a: [^]i64, length: c.size_t) -> i64 {
 if a==nil || length<3 || length>1026 || a[0]<1 || a[0]>1024 || int(length)!=int(a[0])+2 || a[1]<0 || a[1]>a[0] do return -2
 n:=int(a[0]); for i:=0;i<n;i+=1 {if a[i+2]!=0 && a[i+2]!=1 do return -2}
 left:=0; zeros:=0; best:=0
 for right:=0;right<n;right+=1 {if a[right+2]==0 do zeros+=1; for zeros>int(a[1]) {if a[left+2]==0 do zeros-=1; left+=1}; if right-left+1>best do best=right-left+1}
 return i64(best)
}
