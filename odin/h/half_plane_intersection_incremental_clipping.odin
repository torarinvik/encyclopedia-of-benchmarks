// Independently authored draft; not compiled or run.
package half_plane_intersection_incremental_clipping
import "core:c"
Line :: struct { a,b,c: i64 }
Vertex :: struct { x,y,den: i64, incoming: int }
gcd :: proc(a0,b0: i64) -> i64 {
    a,b := a0,b0
    if a<0 { a=-a }; if b<0 { b=-b }
    for b!=0 { r:=a%b; a=b; b=r }
    return a
}
intersect :: proc(a,b: Line, p: ^Vertex) -> bool {
    d:=a.a*b.b-b.a*a.b
    if d==0 do return false
    x,y:=a.c*b.b-a.b*b.c,a.a*b.c-a.c*b.a
    if d<0 { d=-d; x=-x; y=-y }
    g:=gcd(gcd(x,y),d)
    p^=Vertex{x/g,y/g,d/g,0}
    return true
}
side :: proc(l: Line,p: Vertex) -> i64 { return l.a*p.x+l.b*p.y-l.c*p.den }
same :: proc(a,b: Vertex) -> bool { return a.x*b.den==b.x*a.den && a.y*b.den==b.y*a.den }
turn :: proc(a,b,c: Vertex) -> i64 {
    dx1,dy1:=b.x*a.den-a.x*b.den,b.y*a.den-a.y*b.den
    dx2,dy2:=c.x*b.den-b.x*c.den,c.y*b.den-b.y*c.den
    return dx1*dy2-dy1*dx2
}
append :: proc(out: ^[32]Vertex, used: ^int, p: Vertex) {
    if used^==0 || !same(out[used^-1],p) { out[used^]=p; used^+=1 }
}
put :: proc(out: [^]u8, offset: ^int, value: i64) {
    bits:=transmute(u64)value
    for i:=0;i<8;i+=1 { out[offset^]=u8((bits>>uint(8*i))&255); offset^+=1 }
}
@(export)
half_plane_intersection_incremental_clipping :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<1 || length>38 || input[0]<0 || input[0]>12 do return -1
    n:=int(input[0])
    if length!=c.size_t(1+3*n) do return -1
    lines: [16]Line
    lines[0]=Line{-1,0,256}; lines[1]=Line{0,-1,256}; lines[2]=Line{1,0,256}; lines[3]=Line{0,1,256}
    for i:=0;i<n;i+=1 {
        a,b,c0:=input[1+3*i],input[2+3*i],input[3+3*i]
        if a < -16 || a>16 || b < -16 || b>16 || c0 < -128 || c0>128 || (a==0 && b==0) || gcd(a,b)!=1 do return -1
        lines[4+i]=Line{a,b,c0}
    }
    polygon: [32]Vertex
    polygon[0]=Vertex{-256,-256,1,0}; polygon[1]=Vertex{256,-256,1,1}
    polygon[2]=Vertex{256,256,1,2}; polygon[3]=Vertex{-256,256,1,3}
    count:=4
    for line:=4;line<4+n && count>=3;line+=1 {
        next: [32]Vertex; used:=0
        for i:=0;i<count;i+=1 {
            s,e:=polygon[(i+count-1)%count],polygon[i]
            s_in,e_in:=side(lines[line],s)<=0,side(lines[line],e)<=0
            if s_in!=e_in {
                crossing: Vertex
                if !intersect(lines[e.incoming],lines[line],&crossing) do return -1
                if s_in { crossing.incoming=e.incoming } else { crossing.incoming=line }
                append(&next,&used,crossing)
            }
            if e_in { append(&next,&used,e) }
        }
        if used>1 && same(next[0],next[used-1]) { next[0].incoming=next[used-1].incoming; used-=1 }
        count=used; polygon=next
        noncollinear:=false
        for i:=0;i<count && count>=3;i+=1 {
            if turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count])!=0 { noncollinear=true }
        }
        if !noncollinear { count=0 }
    }
    changed:=true
    for changed && count>=3 {
        changed=false
        for i:=0;i<count;i+=1 {
            if turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0 {
                for j:=i;j+1<count;j+=1 { polygon[j]=polygon[j+1] }
                count-=1; changed=true; break
            }
        }
    }
    if count<3 { count=0 }
    first:=0
    for i:=1;i<count;i+=1 {
        yi,yf:=polygon[i].y*polygon[first].den,polygon[first].y*polygon[i].den
        if yi<yf || (yi==yf && polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den) { first=i }
    }
    needed:=(1+4*count)*8
    if output==nil || capacity<c.size_t(needed) do return -2
    offset:=0; put(output,&offset,i64(count))
    for i:=0;i<count;i+=1 {
        p:=polygon[(first+i)%count]
        gx,gy:=gcd(p.x,p.den),gcd(p.y,p.den)
        put(output,&offset,p.x/gx); put(output,&offset,p.den/gx)
        put(output,&offset,p.y/gy); put(output,&offset,p.den/gy)
    }
    return i64(needed)
}
