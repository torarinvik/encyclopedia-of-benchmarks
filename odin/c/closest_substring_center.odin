package closest_substring_center
import "core:c"
// Bounded exact closest-substring center by lexicographic exhaustive search.
@(export)
closest_substring_center :: proc "c" (x:[^]i64,length:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if x==nil do return -2
 if length<4||length>44 do return -1
 nv,mv,lv,qv:=x[0],x[1],x[2],x[3]
 if nv<1||nv>4||mv<1||mv>10||lv<1||lv>8||lv>mv||(qv!=2&&qv!=3)||int(length)!=4+int(nv*mv) do return -1
 n,m,l,q:=int(nv),int(mv),int(lv),int(qv);for i:=4;i<int(length);i+=1{if x[i]<0||x[i]>=qv do return -1}
 total:=1;for _:=0;_<l;_+=1{total*=q};best:=l+1;bc:[8]int;candidate:[8]int
 for code:=0;code<total;code+=1{v:=code;for p:=l-1;p>=0;p-=1{candidate[p]=v%q;v/=q};radius:=0
  for row:=0;row<n;row+=1{rb:=l+1;for st:=0;st+l<=m;st+=1{d:=0;for j:=0;j<l;j+=1{if i64(candidate[j])!=x[4+row*m+st+j]{d+=1}};if d<rb{rb=d}};if rb>radius{radius=rb}}
  if radius<best{best=radius;for j:=0;j<l;j+=1{bc[j]=candidate[j]}}}
 bytes:=8*(l+1);if cap<c.size_t(bytes)||(out==nil&&bytes>0) do return -2
 value:=u64(best);for b:=0;b<8;b+=1{out[b]=u8((value>>(8*b))&255)};for j:=0;j<l;j+=1{value=u64(bc[j]);for b:=0;b<8;b+=1{out[8*(j+1)+b]=u8((value>>(8*b))&255)}};return i64(bytes)
}
