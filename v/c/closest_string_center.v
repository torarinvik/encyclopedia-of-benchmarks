module closest_string_center

// Bounded exact closest-string center by lexicographic exhaustive search.
@[export: 'closest_string_center']
pub fn closest_string_center(x &i64,length usize,out &u8,cap usize)i64{
    unsafe{
        if length<3||length>51{return -1};nv:=x[0];mv:=x[1];qv:=x[2]
        if nv<1||nv>6||mv<1||mv>8||(qv!=2&&qv!=3)||int(length)!=3+int(nv*mv){return -1}
        n:=int(nv);m:=int(mv);q:=int(qv);for i:=3;i<int(length);i++{if x[i]<0||x[i]>=qv{return -1}}
        mut total:=1;for _:=0;_<m;_++{total*=q};mut best:=m+1;mut bestc:=[8]int{}
        for code:=0;code<total;code++{mut v:=code;mut cand:=[8]int{};for p:=m-1;p>=0;p--{cand[p]=v%q;v/=q};mut radius:=0
            for row:=0;row<n;row++{mut d:=0;for col:=0;col<m;col++{if i64(cand[col])!=x[3+row*m+col]{d++}};if d>radius{radius=d}}
            if radius<best{best=radius;bestc=cand}}
        bytes:=8*(m+1);if cap<bytes{return -2};mut value:=u64(best);for b:=0;b<8;b++{out[b]=u8((value>>(8*b))&255)}
        for j:=0;j<m;j++{value=u64(bestc[j]);for b:=0;b<8;b++{out[8*(j+1)+b]=u8((value>>(8*b))&255)}};return i64(bytes)
    }
}
