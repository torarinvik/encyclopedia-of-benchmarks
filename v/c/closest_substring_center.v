module closest_substring_center
// Bounded exact closest-substring center by lexicographic exhaustive search.
@[export: 'closest_substring_center']
pub fn closest_substring_center(x &i64,length usize,out &u8,cap usize)i64{
 unsafe{
  if length<4||length>44{return -1};nv:=x[0];mv:=x[1];lv:=x[2];qv:=x[3]
  if nv<1||nv>4||mv<1||mv>10||lv<1||lv>8||lv>mv||(qv!=2&&qv!=3)||int(length)!=4+int(nv*mv){return -1}
  n:=int(nv);m:=int(mv);l:=int(lv);q:=int(qv);for i:=4;i<int(length);i++{if x[i]<0||x[i]>=qv{return -1}}
  mut total:=1;for _:=0;_<l;_++{total*=q};mut best:=l+1;mut bc:=[8]int{}
  for code:=0;code<total;code++{mut v:=code;mut cand:=[8]int{};for p:=l-1;p>=0;p--{cand[p]=v%q;v/=q};mut radius:=0
   for row:=0;row<n;row++{mut rb:=l+1;for st:=0;st+l<=m;st++{mut d:=0;for j:=0;j<l;j++{if i64(cand[j])!=x[4+row*m+st+j]{d++}};if d<rb{rb=d}};if rb>radius{radius=rb}}
   if radius<best{best=radius;bc=cand}}
  bytes:=8*(l+1);if cap<bytes{return -2};mut z:=u64(best);for b:=0;b<8;b++{out[b]=u8((z>>(8*b))&255)};for j:=0;j<l;j++{z=u64(bc[j]);for b:=0;b<8;b++{out[8*(j+1)+b]=u8((z>>(8*b))&255)}};return i64(bytes)
 }
}
