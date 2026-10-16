package permutations
import "core:c"
next_perm :: proc(a:^([6]i32),n:int)->bool{i:=n-1;for i>0&&a[i-1]>=a[i]{i-=1};if i==0 do return false;j:=n-1;for a[j]<=a[i-1]{j-=1};t:=a[i-1];a[i-1]=a[j];a[j]=t;l:=i;r:=n-1;for l<r{t=a[l];a[l]=a[r];a[r]=t;l+=1;r-=1};return true}
mix :: proc(h:u32,b:u8)->u32{return u32((u64(h^u32(b))*16777619)&0xFFFFFFFF)}
@(export)
permutations :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>7||v[0]<1||v[0]>6||n!=c.size_t(v[0]+1) do return -1;count:=int(v[0]);a:[6]i32;for i:=0;i<count;i+=1{x:=v[i+1];if x < -2147483648||x>2147483647 do return -1;a[i]=i32(x);if i>0&&a[i-1]>=a[i] do return -1};h:=u32(2166136261);for{for i:=0;i<count;i+=1{u:=u32(a[i]);for b:=0;b<4;b+=1{h=mix(h,u8(u>>u32(8*b)))}};h=mix(h,255);if !next_perm(&a,count) do break};return i64(h)}
