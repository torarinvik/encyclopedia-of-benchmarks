package galloping_strategy
import "core:c"
bound_shift :: proc(x:i64)->i64{return 2147483647}
left_run :: proc(a:[^]i64,key,base,hint:i64)(i64,i64){m:=hint+1;x:=i64(1);tmp:=i64(0);for x<m&&key<a[base+hint-x]{tmp=x;x=bound_shift(x)};if x>m{x=m};return hint-tmp,hint-x}
right_run :: proc(a:[^]i64,key,base,length,hint:i64)(i64,i64){x:=i64(1);last:=i64(0);m:=length-hint;for x<m&&key>a[base+hint+x]{last=x;x=bound_shift(x)};if x>m{x=m};return x+hint,last+hint}
final_offset :: proc(a:[^]i64,key,base,offset0,last0:i64,lt:i64)->i64{o:=offset0;l:=last0+1;for l<o{mid:=l+i64((u64(o-l))>>1);cmp:=i64(0);if key>a[base+mid]{cmp=1}else if key<a[base+mid]{cmp=-1};if cmp<lt{o=mid}else{l=mid+1}};return o}
@(export)
galloping_strategy :: proc "c" (v:[^]i64,n:c.size_t)->i64{
    if v==nil||n<5||n>69 do return -1
    op,count,base,length,key:=v[0],v[1],v[2],v[3],v[4]
    if (op!=0&&op!=1)||count<0||count>64||n!=5+c.size_t(count)||base<0||length<0||base>count||length>count-base||key < -2147483648||key>2147483647 do return -1
    if count==0 do return 0
    if length==0||base>=count do return -1
    a:[64]i64
    for i:=0;i<int(count);i+=1{a[i]=v[5+i];if a[i] < -2147483648||a[i]>2147483647 do return -1}
    for i:=base;i+1<base+length;i+=1{if a[i]>a[i+1] do return -1}
    o,l:=i64(0),i64(0)
    if op==0{if key>a[base]{o,l=right_run(&a[0],key,base,length,0)}else{o,l=left_run(&a[0],key,base,0)};return final_offset(&a[0],key,base,o,l,1)}
    if key<a[base]{o,l=left_run(&a[0],key,base,length)}else{o,l=right_run(&a[0],key,base,length,0)}
    return final_offset(&a[0],key,base,o,l,0)
}
