/// Delaunay-rooted reverse search over convex polygon triangulations.
const MAX_N: usize = 8;
const MAX_D: usize = 20;
const MAX_STATES: usize = 132;

#[derive(Clone)]
struct Context {
    n: usize,
    d: usize,
    points: [(i64, i64); MAX_N],
    diagonals: [(usize, usize); MAX_D],
}

fn orient(a: (i64, i64), b: (i64, i64), c: (i64, i64)) -> i64 {
    (b.0-a.0)*(c.1-a.1)-(b.1-a.1)*(c.0-a.0)
}
fn incircle(a:(i64,i64),b:(i64,i64),c:(i64,i64),d:(i64,i64))->i64{
    let (ax,ay,bx,by,cx,cy)=(a.0-d.0,a.1-d.1,b.0-d.0,b.1-d.1,c.0-d.0,c.1-d.1);
    let (al,bl,cl)=(ax*ax+ay*ay,bx*bx+by*by,cx*cx+cy*cy);
    al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx)
}
fn boundary(n:usize,u:usize,v:usize)->bool{v==u+1||(u==0&&v==n-1)}
fn edge_index(c:&Context,u:usize,v:usize)->Option<usize>{(0..c.d).find(|&i|c.diagonals[i]==(u,v))}
fn crosses(a:(usize,usize),b:(usize,usize))->bool{
    (a.0<b.0&&b.0<a.1&&a.1<b.1)||(b.0<a.0&&a.0<b.1&&b.1<a.1)
}
fn adjacency(c:&Context,mask:u32)->[u16;MAX_N]{
    let mut rows=[0u16;MAX_N];
    for u in 0..c.n{let v=(u+1)%c.n;rows[u]|=1u16<<v;rows[v]|=1u16<<u;}
    for i in 0..c.d{if mask&(1u32<<i)!=0{let(u,v)=c.diagonals[i];rows[u]|=1u16<<v;rows[v]|=1u16<<u;}}
    rows
}
fn triangle_count(c:&Context,mask:u32)->usize{
    let rows=adjacency(c,mask);let mut count=0;
    for a in 0..c.n{for b in a+1..c.n{for z in b+1..c.n{if rows[a]&(1<<b)!=0&&rows[b]&(1<<z)!=0&&rows[a]&(1<<z)!=0{count+=1;}}}}
    count
}
fn common_opposites(c:&Context,mask:u32,edge:usize)->Option<(usize,usize)>{
    let rows=adjacency(c,mask);let(u,v)=c.diagonals[edge];let common=rows[u]&rows[v];let mut inside=None;let mut outside=None;let mut found=0;
    for w in 0..c.n{if common&(1<<w)!=0{if u<w&&w<v{inside=Some(w);}else{outside=Some(w);}found+=1;}}
    if found==2{Some((inside?,outside?))}else{None}
}
fn flip(c:&Context,mask:u32,edge:usize,require_lawson:bool)->Option<u32>{
    let(u,v)=c.diagonals[edge];let(inside,outside)=common_opposites(c,mask,edge)?;
    if require_lawson&&incircle(c.points[u],c.points[inside],c.points[v],c.points[outside])<=0{return None;}
    let pair=if inside<outside{(inside,outside)}else{(outside,inside)};let opposite=edge_index(c,pair.0,pair.1)?;
    Some((mask&!(1u32<<edge))|(1u32<<opposite))
}
fn parent(c:&Context,mask:u32)->Option<u32>{for edge in 0..c.d{if mask&(1u32<<edge)!=0{if let Some(p)=flip(c,mask,edge,true){return Some(p);}}}None}
fn valid_root(c:&Context,mask:u32)->bool{
    if triangle_count(c,mask)!=c.n-2{return false;}let rows=adjacency(c,mask);
    for a in 0..c.n{for b in a+1..c.n{for z in b+1..c.n{if rows[a]&(1<<b)!=0&&rows[b]&(1<<z)!=0&&rows[a]&(1<<z)!=0{
        for q in 0..c.n{if q!=a&&q!=b&&q!=z&&incircle(c.points[a],c.points[b],c.points[z],c.points[q])>0{return false;}}
    }}}}
    true
}
fn reverse_search(c:&Context,root:u32)->i64{
    let mut states=[0u32;MAX_STATES];let mut cursor=[0usize;MAX_STATES];let mut top=0usize;let mut count=1i64;states[0]=root;
    loop{
        if cursor[top]>=c.d{if top==0{break;}top-=1;continue;}
        let edge=cursor[top];cursor[top]+=1;if states[top]&(1u32<<edge)==0{continue;}
        if let Some(child)=flip(c,states[top],edge,false){if parent(c,child)==Some(states[top]){if count>=MAX_STATES as i64{return -1;}count+=1;top+=1;states[top]=child;cursor[top]=0;}}
    }
    count
}

#[no_mangle]
pub extern "C" fn delaunay_rooted_triangulation_reverse_search(input:*const i64,length:usize)->i64{
    if input.is_null()||length<2||length>29{return -1;}let values=unsafe{std::slice::from_raw_parts(input,length)};let n64=values[0];
    if !(3..=8).contains(&n64)||length!=4*n64 as usize-4{return -1;}let n=n64 as usize;
    let mut c=Context{n,d:0,points:[(0,0);MAX_N],diagonals:[(0,0);MAX_D]};
    for i in 0..n{let p=(values[1+2*i],values[2+2*i]);if !(-50..=50).contains(&p.0)||!(-50..=50).contains(&p.1){return -1;}c.points[i]=p;}
    for a in 0..n{for b in a+1..n{for z in b+1..n{if orient(c.points[a],c.points[b],c.points[z])<=0{return -1;}}}}
    for a in 0..n{for b in a+1..n{for z in b+1..n{for q in z+1..n{if incircle(c.points[a],c.points[b],c.points[z],c.points[q])==0{return -1;}}}}}
    for u in 0..n{for v in u+1..n{if !boundary(n,u,v){c.diagonals[c.d]=(u,v);c.d+=1;}}}
    let at=1+2*n;if values[at]!=(n-3) as i64{return -1;}let mut root=0u32;let mut previous=None;
    for i in 0..n-3{let(u64,v64)=(values[at+1+2*i],values[at+2+2*i]);if u64<0||u64>=v64||v64>=n64{return -1;}let edge=(u64 as usize,v64 as usize);if boundary(n,edge.0,edge.1)||previous.is_some_and(|old|edge<=old){return -1;}let Some(ix)=edge_index(&c,edge.0,edge.1) else{return -1;};root|=1u32<<ix;previous=Some(edge);}
    let mut seen=0;for i in 0..c.d{if root&(1u32<<i)!=0{seen+=1;for j in i+1..c.d{if root&(1u32<<j)!=0&&crosses(c.diagonals[i],c.diagonals[j]){return -1;}}}}
    if seen!=n-3||!valid_root(&c,root){return -1;}reverse_search(&c,root)
}
