package permutate_string
import "core:c"
next_perm :: proc(a: ^[7]u8, n: int)->bool {i:=n-1;for i>0&&a[i-1]>=a[i]{i-=1};if i==0 do return false;j:=n-1;for a[j]<=a[i-1]{j-=1};t:=a[i-1];a[i-1]=a[j];a[j]=t;l:=i;r:=n-1;for l<r{t=a[l];a[l]=a[r];a[r]=t;l+=1;r-=1};return true}
mix :: proc(h:u32,b:u8)->u32{return u32((u64(h^u32(b))*16777619)&0xFFFFFFFF)}
@(export)
permutate_string :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>8||v[0]<1||v[0]>7||n!=c.size_t(v[0]+1) do return -1;len:=int(v[0]);a:[7]u8;for i:=0;i<len;i+=1{if v[i+1]<33||v[i+1]>126 do return -1;a[i]=u8(v[i+1]);for j:=0;j<i;j+=1{if a[j]==a[i] do return -1}};for i:=1;i<len;i+=1{j:=i;for j>0&&a[j-1]>a[j]{t:=a[j-1];a[j-1]=a[j];a[j]=t;j-=1}};h:=u32(2166136261);for{for i:=0;i<len;i+=1{h=mix(h,a[i])};h=mix(h,0);if !next_perm(&a,len) do break};return i64(h)}
