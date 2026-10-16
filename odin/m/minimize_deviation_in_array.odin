package minimize_deviation_in_array
import "core:c"
push :: proc(h:[^]i64,size:^int,x:i64){i:=size^;size^+=1;for i>0&&h[(i-1)/2]<x{h[i]=h[(i-1)/2];i=(i-1)/2};h[i]=x}
pop :: proc(h:[^]i64,size:^int)->i64{top:=h[0];size^-=1;x:=h[size^];i:=0;for 2*i+1<size^{c0:=2*i+1;if c0+1<size^&&h[c0+1]>h[c0]{c0+=1};if h[c0]<=x{break};h[i]=h[c0];i=c0};if size^>0{h[i]=x};return top}
@(export)
minimize_deviation_in_array :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>65||v[0]<1||v[0]>64||n!=c.size_t(v[0]+1) do return -1;count:=int(v[0]);h:[64]i64;size:=0;low:=i64(9223372036854775807);for k:=0;k<count;k+=1{x:=v[k+1];if x<1||x>1000000 do return -1;if x%2==1{x*=2};if x<low do low=x;push(&h,&size,x)};best:=h[0]-low;for h[0]%2==0{x:=pop(&h,&size)/2;if x<low do low=x;push(&h,&size,x);d:=h[0]-low;if d<best do best=d};return best}
