package closest_string_center

import "core:c"

// Bounded exact closest-string center by lexicographic exhaustive search.
@(export)
closest_string_center :: proc "c" (x:[^]i64,length:c.size_t,out:[^]u8,cap:c.size_t)->i64{
    if x==nil do return -2
    if length<3||length>51 do return -1
    nv,mv,qv:=x[0],x[1],x[2]
    if nv<1||nv>6||mv<1||mv>8||(qv!=2&&qv!=3)||int(length)!=3+int(nv*mv) do return -1
    n,m,q:=int(nv),int(mv),int(qv);for i:=3;i<int(length);i+=1{if x[i]<0||x[i]>=qv do return -1}
    total:=1;for _:=0;_<m;_+=1{total*=q};best:=m+1;bestc:[8]int;candidate:[8]int
    for code:=0;code<total;code+=1{v:=code;for p:=m-1;p>=0;p-=1{candidate[p]=v%q;v/=q};radius:=0
        for row:=0;row<n;row+=1{d:=0;for col:=0;col<m;col+=1{if i64(candidate[col])!=x[3+row*m+col]{d+=1}};if d>radius{radius=d}}
        if radius<best{best=radius;for j:=0;j<m;j+=1{bestc[j]=candidate[j]}}}
    bytes:=8*(m+1);if cap<c.size_t(bytes)||(out==nil&&bytes>0) do return -2
    value:=u64(best);for b:=0;b<8;b+=1{out[b]=u8((value>>(8*b))&255)}
    for j:=0;j<m;j+=1{value=u64(bestc[j]);for b:=0;b<8;b+=1{out[8*(j+1)+b]=u8((value>>(8*b))&255)}}
    return i64(bytes)
}
