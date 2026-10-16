package generic_heap
import "core:c"

hashv :: proc "contextless" (h0:u64,v:i64)->u64{h:=h0;bits:=transmute(u64)v;for i:=u32(0);i<8;i+=1{h=(h~((bits>>(8*i))&255))*0x100000001b3};return h}
@(export)
generic_heap :: proc "c" (a:[^]i64,n:c.size_t)->i64{
 if a==nil||n<1||n>769||a[0]<0||a[0]>256||n!=c.size_t(1+3*a[0]) do return -1
 ids:[128]i64;ps:[128]i64;pos:[4096]i32;for i:=0;i<4096;i+=1{pos[i]=-1};z:=0;h:=u64(0xcbf29ce484222325)
 for k:=0;k<int(a[0]);k+=1{op:=a[1+3*k];id:=a[2+3*k];v:=a[3+3*k]
 if op==0{if id<0||id>=4096||v< -2147483648||v>2147483647||pos[id]>=0||z>=128 do return -1;ids[z]=id;ps[z]=v;pos[id]=i32(z);i:=z;z+=1;for i>0{q:=(i-1)/2;if ps[i]<=ps[q] do break;ids[i],ids[q]=ids[q],ids[i];ps[i],ps[q]=ps[q],ps[i];pos[ids[i]]=i32(i);pos[ids[q]]=i32(q);i=q}}
 else if op==1||op==2{if id!=0||v!=0||z==0 do return -1;ri:=ids[0];rv:=ps[0];if op==2{ids[0],ids[z-1]=ids[z-1],ids[0];ps[0],ps[z-1]=ps[z-1],ps[0];pos[ids[0]]=0;pos[ids[z-1]]=i32(z-1);z-=1;pos[ri]=-1;if z>0{i:=0;for 2*i+1<z{q:=2*i+1;if q+1<z&&ps[q+1]>ps[q]{q+=1};if ps[i]>=ps[q] do break;ids[i],ids[q]=ids[q],ids[i];ps[i],ps[q]=ps[q],ps[i];pos[ids[i]]=i32(i);pos[ids[q]]=i32(q);i=q}}};h=hashv(hashv(h,ri),rv)}
 else if op==3{if id<0||id>=4096||v< -2147483648||v>2147483647||pos[id]<0 do return -1;i:=int(pos[id]);ps[i]=v;for i>0{q:=(i-1)/2;if ps[i]<=ps[q] do break;ids[i],ids[q]=ids[q],ids[i];ps[i],ps[q]=ps[q],ps[i];pos[ids[i]]=i32(i);pos[ids[q]]=i32(q);i=q}}
 else if op==4||op==5{if id!=0||v!=0 do return -1;obs:=i64(z);if op==5{obs=i64(z==0)};h=hashv(h,obs)}else{return -1}}
 return transmute(i64)h
}
