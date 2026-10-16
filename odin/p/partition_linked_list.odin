package partition_linked_list
import "core:c"
MODULUS :: 1000000007
BASE :: 2000000003
@(export)
partition_linked_list :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>66||v[0]<0||v[0]>64||n!=c.size_t(v[0]+2)||v[1] < -2147483648||v[1]>2147483647 do return -1;count:=int(v[0]);less:[64]i64;ge:[64]i64;l:=0;g:=0;for i:=0;i<count;i+=1{x:=v[i+2];if x < -2147483648||x>2147483647 do return -1;if x<v[1]{less[l]=x;l+=1}else{ge[g]=x;g+=1}};h:=i64(0);for i:=0;i<l;i+=1{h=(h*BASE+less[i]+2147483648)%MODULUS};for i:=0;i<g;i+=1{h=(h*BASE+ge[i]+2147483648)%MODULUS};return h}
