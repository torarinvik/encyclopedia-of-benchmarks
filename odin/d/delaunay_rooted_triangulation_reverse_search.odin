package delaunay_rooted_triangulation_reverse_search

// Delaunay-rooted reverse search over convex polygon triangulations.
import "core:c"

MAX_N :: 8
MAX_D :: 20
MAX_STATES :: 132

Point :: struct { x, y: i64 }
Edge :: struct { u, v: int }
Context :: struct { n, d: int, points: [MAX_N]Point, diagonals: [MAX_D]Edge }

orient :: proc(a,b,z:Point)->i64 { return (b.x-a.x)*(z.y-a.y)-(b.y-a.y)*(z.x-a.x) }
incircle :: proc(a,b,z,d:Point)->i64 {
    ax,ay,bx,by,cx,cy:=a.x-d.x,a.y-d.y,b.x-d.x,b.y-d.y,z.x-d.x,z.y-d.y
    al,bl,cl:=ax*ax+ay*ay,bx*bx+by*by,cx*cx+cy*cy
    return al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx)
}
boundary :: proc(n,u,v:int)->bool { return v==u+1||(u==0&&v==n-1) }
edge_index :: proc(c:^Context,u,v:int)->int { for i in 0..<c.d { if c.diagonals[i].u==u&&c.diagonals[i].v==v{return i} };return -1 }
crosses :: proc(a,b:Edge)->bool { return (a.u<b.u&&b.u<a.v&&a.v<b.v)||(b.u<a.u&&a.u<b.v&&b.v<a.v) }

adjacency :: proc(c:^Context,mask:u32)->[MAX_N]u16 {
    rows:=[MAX_N]u16{}
    for u in 0..<c.n { v:=(u+1)%c.n;rows[u]|=u16(1)<<v;rows[v]|=u16(1)<<u }
    for i in 0..<c.d { if (mask&(u32(1)<<i))!=0 { e:=c.diagonals[i];rows[e.u]|=u16(1)<<e.v;rows[e.v]|=u16(1)<<e.u } }
    return rows
}
triangle_count :: proc(c:^Context,mask:u32)->int {
    rows:=adjacency(c,mask);count:=0
    for a in 0..<c.n { for b in a+1..<c.n { for z in b+1..<c.n { if (rows[a]&(u16(1)<<b))!=0&&(rows[b]&(u16(1)<<z))!=0&&(rows[a]&(u16(1)<<z))!=0{count+=1} } } }
    return count
}
common_opposites :: proc(c:^Context,mask:u32,edge:int)->(bool,int,int) {
    rows:=adjacency(c,mask);e:=c.diagonals[edge];common:=rows[e.u]&rows[e.v]
    inside,outside,found:=-1,-1,0
    for w in 0..<c.n { if (common&(u16(1)<<w))!=0 { if e.u<w&&w<e.v{inside=w}else{outside=w};found+=1 } }
    return found==2&&inside>=0&&outside>=0,inside,outside
}
flip_state :: proc(c:^Context,mask:u32,edge:int,require_lawson:bool)->i64 {
    e:=c.diagonals[edge];ok,inside,outside:=common_opposites(c,mask,edge);if !ok{return -1}
    if require_lawson&&incircle(c.points[e.u],c.points[inside],c.points[e.v],c.points[outside])<=0{return -1}
    lo,hi:=inside,outside;if lo>hi{lo,hi=hi,lo};opposite:=edge_index(c,lo,hi);if opposite<0{return -1}
    return i64((mask&~(u32(1)<<edge))|(u32(1)<<opposite))
}
parent_state :: proc(c:^Context,mask:u32)->i64 {
    for edge in 0..<c.d { if (mask&(u32(1)<<edge))!=0 { p:=flip_state(c,mask,edge,true);if p>=0{return p} } }
    return -1
}
valid_root :: proc(c:^Context,mask:u32)->bool {
    if triangle_count(c,mask)!=c.n-2{return false};rows:=adjacency(c,mask)
    for a in 0..<c.n { for b in a+1..<c.n { for z in b+1..<c.n { if (rows[a]&(u16(1)<<b))!=0&&(rows[b]&(u16(1)<<z))!=0&&(rows[a]&(u16(1)<<z))!=0 { for q in 0..<c.n { if q!=a&&q!=b&&q!=z&&incircle(c.points[a],c.points[b],c.points[z],c.points[q])>0{return false} } } } } }
    return true
}
reverse_search :: proc(c:^Context,root:u32)->i64 {
    states:=[MAX_STATES]u32{};cursor:=[MAX_STATES]int{};top,count:=0,1;states[0]=root
    for top>=0 { if cursor[top]>=c.d { top-=1;continue };edge:=cursor[top];cursor[top]+=1;if (states[top]&(u32(1)<<edge))==0{continue};child:=flip_state(c,states[top],edge,false);if child<0{continue};p:=parent_state(c,u32(child));if p!=i64(states[top]){continue};if count>=MAX_STATES{return -1};count+=1;top+=1;states[top]=u32(child);cursor[top]=0 }
    return i64(count)
}

@(export)
delaunay_rooted_triangulation_reverse_search :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil||length<2||length>29{return -1};n64:=input[0];if n64<3||n64>8||i64(length)!=4*n64-4{return -1};n:=int(n64)
    c:=Context{n=n}
    for i in 0..<n { x,y:=input[1+2*i],input[2+2*i];if x< -50||x>50||y< -50||y>50{return -1};c.points[i]=Point{x,y} }
    for a in 0..<n { for b in a+1..<n { for z in b+1..<n { if orient(c.points[a],c.points[b],c.points[z])<=0{return -1} } } }
    for a in 0..<n { for b in a+1..<n { for z in b+1..<n { for q in z+1..<n { if incircle(c.points[a],c.points[b],c.points[z],c.points[q])==0{return -1} } } } }
    for u in 0..<n { for v in u+1..<n { if !boundary(n,u,v){c.diagonals[c.d]=Edge{u,v};c.d+=1} } }
    at:=1+2*n;if input[at]!=i64(n-3){return -1};root:=u32(0);previous:=Edge{-1,-1}
    for i in 0..<n-3 { u64,v64:=input[at+1+2*i],input[at+2+2*i];if u64<0||u64>=v64||v64>=n64{return -1};e:=Edge{int(u64),int(v64)};if boundary(n,e.u,e.v)||(i>0&&(e.u<previous.u||(e.u==previous.u&&e.v<=previous.v))){return -1};ix:=edge_index(&c,e.u,e.v);if ix<0{return -1};root|=u32(1)<<ix;previous=e }
    seen:=0;for i in 0..<c.d { if (root&(u32(1)<<i))!=0 { seen+=1;for j in i+1..<c.d { if (root&(u32(1)<<j))!=0&&crosses(c.diagonals[i],c.diagonals[j]){return -1} } } }
    if seen!=n-3||!valid_root(&c,root){return -1};return reverse_search(&c,root)
}
