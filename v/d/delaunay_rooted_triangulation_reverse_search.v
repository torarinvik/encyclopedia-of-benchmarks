module delaunay_rooted_triangulation_reverse_search

const max_n = 8
const max_d = 20
const max_states = 132

struct Point { x i64; y i64 }
struct Edge { u int; v int }
struct Context { n int; d int; points [max_n]Point; diagonals [max_d]Edge }

fn orient(a Point,b Point,c Point) i64 { return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x) }
fn incircle(a Point,b Point,c Point,d Point) i64 {
    ax:=a.x-d.x;ay:=a.y-d.y;bx:=b.x-d.x;by:=b.y-d.y;cx:=c.x-d.x;cy:=c.y-d.y
    al:=ax*ax+ay*ay;bl:=bx*bx+by*by;cl:=cx*cx+cy*cy
    return al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx)
}
fn boundary(n int,u int,v int) bool { return v==u+1||(u==0&&v==n-1) }
fn edge_index(c Context,u int,v int) int { for i in 0..c.d { if c.diagonals[i].u==u&&c.diagonals[i].v==v{return i} };return -1 }
fn crosses(a Edge,b Edge) bool { return (a.u<b.u&&b.u<a.v&&a.v<b.v)||(b.u<a.u&&a.u<b.v&&b.v<a.v) }
fn adjacency(c Context,mask u32) [max_n]u16 {
    mut rows:=[max_n]u16{}
    for u in 0..c.n { v:=(u+1)%c.n;rows[u]|=u16(1)<<v;rows[v]|=u16(1)<<u }
    for i in 0..c.d { if (mask&(u32(1)<<i))!=0 { u:=c.diagonals[i].u;v:=c.diagonals[i].v;rows[u]|=u16(1)<<v;rows[v]|=u16(1)<<u } }
    return rows
}
fn triangle_count(c Context,mask u32) int {
    rows:=adjacency(c,mask);mut count:=0
    for a in 0..c.n { for b in a+1..c.n { for z in b+1..c.n { if (rows[a]&(u16(1)<<b))!=0&&(rows[b]&(u16(1)<<z))!=0&&(rows[a]&(u16(1)<<z))!=0{count++} } } }
    return count
}
fn common_opposites(c Context,mask u32,edge int) (int,int) {
    rows:=adjacency(c,mask);u:=c.diagonals[edge].u;v:=c.diagonals[edge].v;common:=rows[u]&rows[v]
    mut inside:=-1;mut outside:=-1;mut found:=0
    for w in 0..c.n { if (common&(u16(1)<<w))!=0 { if u<w&&w<v{inside=w}else{outside=w};found++ } }
    if found!=2||inside<0||outside<0{return -1,-1};return inside,outside
}
fn flip_state(c Context,mask u32,edge int,require_lawson bool) i64 {
    u:=c.diagonals[edge].u;v:=c.diagonals[edge].v;inside,outside:=common_opposites(c,mask,edge);if inside<0{return -1}
    if require_lawson&&incircle(c.points[u],c.points[inside],c.points[v],c.points[outside])<=0{return -1}
    lo:=inside;hi:=outside;if lo>hi{lo,hi=hi,lo};opposite:=edge_index(c,lo,hi);if opposite<0{return -1}
    return i64((mask&~(u32(1)<<edge))|(u32(1)<<opposite))
}
fn parent_state(c Context,mask u32) i64 {
    for edge in 0..c.d { if (mask&(u32(1)<<edge))!=0 { next:=flip_state(c,mask,edge,true);if next>=0{return next} } };return -1
}
fn valid_root(c Context,mask u32) bool {
    if triangle_count(c,mask)!=c.n-2{return false};rows:=adjacency(c,mask)
    for a in 0..c.n { for b in a+1..c.n { for z in b+1..c.n { if (rows[a]&(u16(1)<<b))!=0&&(rows[b]&(u16(1)<<z))!=0&&(rows[a]&(u16(1)<<z))!=0 { for q in 0..c.n { if q!=a&&q!=b&&q!=z&&incircle(c.points[a],c.points[b],c.points[z],c.points[q])>0{return false} } } } } }
    return true
}
fn reverse_search(c Context,root u32) i64 {
    mut states:=[max_states]u32{};mut cursor:=[max_states]int{};mut top:=0;mut count:=1;states[0]=root
    for top>=0 { if cursor[top]>=c.d { top--;continue };edge:=cursor[top];cursor[top]++;if (states[top]&(u32(1)<<edge))==0{continue};child:=flip_state(c,states[top],edge,false);if child<0{continue};parent:=parent_state(c,u32(child));if parent!=i64(states[top]){continue};if count>=max_states{return -1};count++;top++;states[top]=u32(child);cursor[top]=0 }
    return i64(count)
}

@[export: 'delaunay_rooted_triangulation_reverse_search']
pub fn delaunay_rooted_triangulation_reverse_search(input &i64,length usize) i64 {
    unsafe {
        if input==nil||length<2||length>29{return -1};n64:=input[0];if n64<3||n64>8||i64(length)!=4*n64-4{return -1};n:=int(n64)
        mut c:=Context{n:n};for i in 0..n{x:=input[1+2*i];y:=input[2+2*i];if x< -50||x>50||y< -50||y>50{return -1};c.points[i]=Point{x,y}}
        for a in 0..n{for b in a+1..n{for z in b+1..n{if orient(c.points[a],c.points[b],c.points[z])<=0{return -1}}}}
        for a in 0..n{for b in a+1..n{for z in b+1..n{for q in z+1..n{if incircle(c.points[a],c.points[b],c.points[z],c.points[q])==0{return -1}}}}}
        for u in 0..n{for v in u+1..n{if !boundary(n,u,v){c.diagonals[c.d]=Edge{u,v};c.d++}}}
        at:=1+2*n;if input[at]!=i64(n-3){return -1};mut root:=u32(0);mut previous:=Edge{-1,-1}
        for i in 0..n-3{u64:=input[at+1+2*i];v64:=input[at+2+2*i];if u64<0||u64>=v64||v64>=n64{return -1};edge:=Edge{int(u64),int(v64)};if boundary(n,edge.u,edge.v)||(i>0&&(edge.u<previous.u||(edge.u==previous.u&&edge.v<=previous.v))){return -1};ix:=edge_index(c,edge.u,edge.v);if ix<0{return -1};root|=u32(1)<<ix;previous=edge}
        mut seen:=0;for i in 0..c.d{if (root&(u32(1)<<i))!=0{seen++;for j in i+1..c.d{if (root&(u32(1)<<j))!=0&&crosses(c.diagonals[i],c.diagonals[j]){return -1}}}}
        if seen!=n-3||!valid_root(c,root){return -1};return reverse_search(c,root)
    }
}
