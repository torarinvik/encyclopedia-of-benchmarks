package char_array_left_rotation
import "core:c"
MAX_LEN::256
reverse_bytes::proc(a:^u8,from,to:int){left:=from;right:=to;for left<right{t:=a[left];a[left]=a[right];a[right]=t;left+=1;right-=1}}
@(export)
char_array_left_rotation::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<2||length>259 do return -1;if input[0]<0||input[0]>256 do return -1;n:=int(input[0]);if input[1]<0||input[1]>i64(n)||length!=c.size_t(n+2) do return -1;for i:=0;i<n;i+=1{if input[i+2]<0||input[i+2]>127 do return -1};if output==nil||capacity<c.size_t(n) do return -2;a:[MAX_LEN]u8;for i:=0;i<n;i+=1{a[i]=u8(input[i+2])};k:=int(input[1]);if k>0 do reverse_bytes(&a[0],0,k-1);if k<n do reverse_bytes(&a[0],k,n-1);if n>0 do reverse_bytes(&a[0],0,n-1);for i:=0;i<n;i+=1{output[i]=a[i]};return i64(n)}
