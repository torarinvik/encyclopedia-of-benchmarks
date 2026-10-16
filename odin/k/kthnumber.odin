package kthnumber
import "core:c"
partition :: proc(a: ^[16]i64,lo,hi:i64)->i64{pivot:=a[hi];i:=lo;for j:=lo;j<hi;j+=1{if a[j]<pivot{a[i],a[j]=a[j],a[i];i+=1}};a[i],a[hi]=a[hi],a[i];return i}
@(export) kthnumber :: proc "c"(v:[^]i64,n:c.size_t)->i64{if n<4||n>19{return -1};count,mode,k:=v[0],v[1],v[2];if count<1||count>16||n!=count+3||(mode!=1&&mode!=2)||k<1||k>count{return -1};a:[16]i64;for i:i64=0;i<count;i+=1{a[i]=v[i+3];if a[i]<-10000||a[i]>10000{return -1}};target:=k-1;if mode==2{target=count-k};lo:i64=0;hi:=count-1;for lo<=hi{q:=partition(&a,lo,hi);if q==target{return a[q]};if q<target{lo=q+1}else{hi=q-1}};return -1}
