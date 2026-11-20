const MAX_EDGES: usize = 8;
const MAX_CELLS: usize = 46;
const MAX_DEPTH: i32 = 4;
const MAX_WORDS: usize = 127;

#[derive(Clone, Copy, Default)]
struct Cell {
    depth: i32,
    prefix: i32,
    lo: i32,
    alt_lo: i32,
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    endpoint_count: i32,
}
#[derive(Clone, Copy, Default)]
struct Edge {
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    start_cell: i32,
    end_cell: i32,
    negative: bool,
}
#[derive(Clone, Copy, Default)]
struct Point { x: i32, y: i32 }
#[derive(Clone, Copy, Default)]
struct Exit { edge: usize, side: i32, num: i64, den: i64 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    i64::from(b.x-a.x)*i64::from(c.y-a.y)-i64::from(b.y-a.y)*i64::from(c.x-a.x)
}
fn on_segment(a: Point, b: Point, p: Point) -> bool {
    p.x>=a.x.min(b.x)&&p.x<=a.x.max(b.x)&&p.y>=a.y.min(b.y)&&p.y<=a.y.max(b.y)
}
fn intersects(a: Point,b: Point,c: Point,d: Point)->bool {
    let (o1,o2,o3,o4)=(orient(a,b,c),orient(a,b,d),orient(c,d,a),orient(c,d,b));
    if o1==0&&on_segment(a,b,c)||o2==0&&on_segment(a,b,d)||o3==0&&on_segment(c,d,a)||o4==0&&on_segment(c,d,b){return true;}
    o1*o2<0&&o3*o4<0
}
fn positive_key(x:i32,y:i32)->i32 {
    let mut key=0; for bit in (4..=7).rev(){key=(key<<2)|(((x>>bit)&1)<<1)|((y>>bit)&1);} key
}
fn remap(q:i32)->i32 { [2,0,3,1][q as usize] }
fn alt_prefix(depth:i32,prefix:i32)->i32 {
    let mut out=0; for shift in (0..2*(depth-1)+1).step_by(2).rev(){out=(out<<2)|remap((prefix>>shift)&3);} out
}
fn cell_box(cell:&mut Cell) {
    let(mut x,mut y)=(0,0);
    for shift in (0..2*(cell.depth-1)+1).step_by(2).rev(){let q=(cell.prefix>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1);}
    let side=256>>cell.depth;cell.x0=x*side;cell.y0=y*side;cell.x1=cell.x0+side;cell.y1=cell.y0+side;
}
fn find_cell(cells:&[Cell;MAX_CELLS],c:usize,key:i32)->Option<usize>{
    (0..c).find(|&i|{let span=1<<(2*(MAX_DEPTH-cells[i].depth));key>=cells[i].lo&&key<cells[i].lo+span})
}
fn sweep_box(cell:Cell,rotated:bool)->(i32,i32,i32,i32){
    if rotated{(256-cell.y1,cell.x0,256-cell.y0,cell.x1)}else{(cell.x0,cell.y0,cell.x1,cell.y1)}
}
fn sweep_edge(edge:Edge,rotated:bool)->(Point,Point){
    if rotated{(Point{x:256-edge.y0,y:edge.x0},Point{x:256-edge.y1,y:edge.x1})}
    else{(Point{x:edge.x0,y:edge.y0},Point{x:edge.x1,y:edge.y1})}
}
fn segment_box(edge:Edge,cell:Cell,rotated:bool)->bool{
    let(x0,y0,x1,y1)=sweep_box(cell,rotated);let(a,b)=sweep_edge(edge,rotated);
    if a.x>=x0&&a.x<=x1&&a.y>=y0&&a.y<=y1||b.x>=x0&&b.x<=x1&&b.y>=y0&&b.y<=y1{return true;}
    let corners=[Point{x:x0,y:y0},Point{x:x1,y:y0},Point{x:x1,y:y1},Point{x:x0,y:y1}];
    (0..4).any(|i|intersects(a,b,corners[i],corners[(i+1)&3]))
}
fn append(path:&mut [Point;33],len:&mut usize,p:Point)->bool{
    if *len>0&&path[*len-1].x==p.x&&path[*len-1].y==p.y{return true;}if *len>=33{return false;}path[*len]=p;*len+=1;true
}
fn frontier(cells:&[Cell;MAX_CELLS],c:usize,order:&[usize;MAX_CELLS],cut:usize,rotated:bool)
    ->Option<([Point;33],usize,usize)>{
    let mut rank=[0usize;MAX_CELLS];for i in 0..c{rank[order[i]]=i;}
    let mut atom_cell=[usize::MAX;256];
    for pos in 0..c{let id=order[pos];let start=if rotated{cells[id].alt_lo}else{cells[id].lo};let span=1<<(2*(MAX_DEPTH-cells[id].depth));for k in start..start+span{atom_cell[k as usize]=id;}}
    let mut processed=[[false;16];16];
    for key in 0..256{let id=atom_cell[key];if id==usize::MAX{return None;}let(mut x,mut y)=(0,0);for shift in (0..=6).rev().step_by(2){let q=(key as i32>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1);}processed[x as usize][y as usize]=rank[id]<cut;}
    let mut heights=[0i32;16];
    for x in 0..16{let mut h=0;while h<16&&processed[x][h as usize]{h+=1;}for y in 0..16{if processed[x][y]!=(y<h as usize){return None;}}heights[x]=h;if x>0&&heights[x-1]<h{return None;}}
    let mut path=[Point::default();33];let mut len=0;
    if !append(&mut path,&mut len,Point{x:0,y:256}){return None;}
    for y in (heights[0]..16).rev(){if !append(&mut path,&mut len,Point{x:0,y:y*16}){return None;}}
    for x in 0..16{let h=heights[x];if !append(&mut path,&mut len,Point{x:(x as i32+1)*16,y:h*16}){return None;}let next=if x<15{heights[x+1]}else{0};for y in (next..h).rev(){if !append(&mut path,&mut len,Point{x:(x as i32+1)*16,y:y*16}){return None;}}}
    if path[0].x!=0||path[0].y!=256||path[len-1].x!=256||path[len-1].y!=0{return None;}
    let(x0,y0,_,_)=sweep_box(cells[order[cut]],rotated);
    let corner=(0..len).find(|&i|path[i].x==x0&&path[i].y==y0)?;
    Some((path,len,corner))
}
fn crossing_segment(a:Point,b:Point,path:&[Point;33],len:usize)->Option<usize>{
    let mut found=None;for i in 0..len-1{if intersects(a,b,path[i],path[i+1]){if found.is_some(){return None;}found=Some(i);}}found
}
fn exit_for_cell(a:Point,b:Point,box_: (i32,i32,i32,i32),id:usize)->Option<Exit>{
    let(x0,y0,x1,y1)=box_;let(dx,dy)=(i64::from(b.x-a.x),i64::from(b.y-a.y));let mut found=None;
    if dy>0{let ydist=i64::from(y1-a.y);let num=i64::from(a.x)*dy+ydist*dx;if ydist>0&&ydist<dy&&i64::from(x0)*dy<num&&num<i64::from(x1)*dy{found=Some(Exit{edge:id,side:0,num,den:dy});}}
    if dx>0{let xdist=i64::from(x1-a.x);let num=i64::from(a.y)*dx+xdist*dy;if xdist>0&&xdist<dx&&i64::from(y0)*dx<num&&num<i64::from(y1)*dx{if found.is_some(){return None;}found=Some(Exit{edge:id,side:1,num,den:dx});}}
    found
}
fn exit_less(a:Exit,b:Exit)->bool{let l=a.num*b.den;let r=b.num*a.den;l<r||(l==r&&a.edge<b.edge)}
fn run_sweep(cells:&[Cell;MAX_CELLS],c:usize,edges:&[Edge;MAX_EDGES],n:usize,
             endpoints:&[[usize;2];MAX_EDGES],rotated:bool,masks:&mut [u64;MAX_CELLS])->bool{
    let mut order=[0usize;MAX_CELLS];for i in 0..c{order[i]=i;}
    if rotated{order[..c].sort_by_key(|&i|cells[i].alt_lo);}
    let mut edge_a=[Point::default();MAX_EDGES];let mut edge_b=[Point::default();MAX_EDGES];let mut ids=[0usize;MAX_EDGES];let mut keys=[0i32;MAX_EDGES];let mut m=0;
    for id in 0..n{if edges[id].negative==rotated{(edge_a[id],edge_b[id])=sweep_edge(edges[id],rotated);let key=positive_key(edge_a[id].x,edge_a[id].y);let mut at=m;m+=1;while at>0&&(keys[at-1]>key||(keys[at-1]==key&&ids[at-1]>id)){keys[at]=keys[at-1];ids[at]=ids[at-1];at-=1;}keys[at]=key;ids[at]=id;}}
    let mut sl=[0usize;MAX_EDGES];let mut sb=[0usize;MAX_EDGES];let(mut sln,mut sbn)=(0usize,0usize);
    for pos in 0..c{let cid=order[pos];let box_=sweep_box(cells[cid],rotated);let mut cand=[0usize;16];let mut cn=0;
        while sln>0&&segment_box(edges[sl[sln-1]],cells[cid],rotated){sln-=1;cand[cn]=sl[sln];cn+=1;}
        while sbn>0&&segment_box(edges[sb[sbn-1]],cells[cid],rotated){sbn-=1;cand[cn]=sb[sbn];cn+=1;}
        for q in 0..m{let id=ids[q];if endpoints[id][0]==cid{cand[cn]=id;cn+=1;}}
        let mut exits=[Exit::default();16];let mut en=0;
        for q in 0..cn{let id=cand[q];masks[cid]|=1u64<<id;if endpoints[id][1]==cid{continue;}let Some(e)=exit_for_cell(edge_a[id],edge_b[id],box_,id)else{return false;};exits[en]=e;en+=1;}
        exits[..en].sort_by(|a,b|a.side.cmp(&b.side).then_with(||if exit_less(*a,*b){core::cmp::Ordering::Less}else if exit_less(*b,*a){core::cmp::Ordering::Greater}else{core::cmp::Ordering::Equal}));
        for e in exits[..en].iter(){if e.side==0{if sln>=MAX_EDGES{return false;}sl[sln]=e.edge;sln+=1;}else{if sbn>=MAX_EDGES{return false;}sb[sbn]=e.edge;sbn+=1;}}
        if pos+1==c{continue;}let Some((path,plen,corner))=frontier(cells,c,&order,pos+1,rotated)else{return false;};let next_box=sweep_box(cells[order[pos+1]],rotated);
        if next_box.1>box_.1{while sln>0{let id=sl[sln-1];let Some(where_)=crossing_segment(edge_a[id],edge_b[id],&path,plen)else{return false;};if where_<corner{break;}sln-=1;if sbn>=MAX_EDGES{return false;}sb[sbn]=id;sbn+=1;}}
        else{while sbn>0{let id=sb[sbn-1];let Some(where_)=crossing_segment(edge_a[id],edge_b[id],&path,plen)else{return false;};if where_>=corner{break;}sbn-=1;if sln>=MAX_EDGES{return false;}sl[sln]=id;sln+=1;}}
    }
    sln==0&&sbn==0
}
fn parse_and_run(values:&[i64],masks:&mut [u64;MAX_CELLS],cell_count:&mut usize)->bool{
    if values.len()<2||values.len()>MAX_WORDS{return false;}let(nv,cv)=(values[0],values[1]);if nv<0||nv>8||cv<1||cv>46{return false;}let(n,c)=(nv as usize,cv as usize);
    if values.len()!=2+2*c+4*n{return false;}let mut cells=[Cell::default();MAX_CELLS];let mut pos=2usize;let mut previous=0i32;
    for i in 0..c{let(d,p)=(values[pos],values[pos+1]);pos+=2;if d<0||d>4||p<0||p>=(1i64<<(2*d)){return false;}let cell=&mut cells[i];cell.depth=d as i32;cell.prefix=p as i32;let span=1<<(2*(4-cell.depth));cell.lo=cell.prefix*span;if cell.lo!=previous{return false;}previous=cell.lo+span;cell_box(cell);}
    if previous!=256||n==0&&(c!=1||cells[0].depth!=0||cells[0].prefix!=0){return false;}
    for cell in cells.iter_mut().take(c){cell.alt_lo=alt_prefix(cell.depth,cell.prefix)<<(2*(4-cell.depth));}
    let mut edges=[Edge::default();MAX_EDGES];let mut endpoints=[[0usize;2];MAX_EDGES];let mut pts=[Point::default();2*MAX_EDGES];
    for i in 0..n{let v=[values[pos],values[pos+1],values[pos+2],values[pos+3]];pos+=4;if v.iter().any(|&x|x<0||x>255||x%16==0){return false;}let(mut x0,mut y0,mut x1,mut y1)=(v[0] as i32,v[1] as i32,v[2] as i32,v[3] as i32);if x0==x1&&y0==y1||y0==y1{return false;}if x0>x1||x0==x1&&y0>y1{core::mem::swap(&mut x0,&mut x1);core::mem::swap(&mut y0,&mut y1);}if x0==x1&&y1<=y0{return false;}
        edges[i]=Edge{x0,y0,x1,y1,start_cell:-1,end_cell:-1,negative:y1<y0};pts[2*i]=Point{x:x0,y:y0};pts[2*i+1]=Point{x:x1,y:y1};
        for gx in (0..=256).step_by(16){for gy in (0..=256).step_by(16){let p=Point{x:gx,y:gy};if orient(pts[2*i],pts[2*i+1],p)==0&&on_segment(pts[2*i],pts[2*i+1],p){return false;}}}
        for j in 0..2*i{if pts[j].x==x0&&pts[j].y==y0{return false;}}for j in 0..2*i+1{if pts[j].x==x1&&pts[j].y==y1{return false;}}
        for j in 0..i{if intersects(pts[2*i],pts[2*i+1],pts[2*j],pts[2*j+1]){return false;}}
        let Some(a)=find_cell(&cells,c,positive_key(x0,y0))else{return false;};let Some(b)=find_cell(&cells,c,positive_key(x1,y1))else{return false;};endpoints[i]=[a,b];edges[i].start_cell=a as i32;edges[i].end_cell=b as i32;cells[a].endpoint_count+=1;cells[b].endpoint_count+=1;
    }
    if cells[..c].iter().any(|cell|cell.endpoint_count>1){return false;}
    let mut parent_d=[0i32;85];let mut parent_p=[0i32;85];let mut pc=0;
    for cell in cells.iter().take(c){for d in 0..cell.depth{let p=cell.prefix>>(2*(cell.depth-d));if !(0..pc).any(|q|parent_d[q]==d&&parent_p[q]==p){parent_d[pc]=d;parent_p[pc]=p;pc+=1;}}}
    for q in 0..pc{let(d,p)=(parent_d[q],parent_p[q]);let mut occupied=0u32;for cell in cells.iter().take(c){if cell.endpoint_count==0||cell.depth<=d{continue;}if cell.prefix>>(2*(cell.depth-d))==p{occupied|=1<<((cell.prefix>>(2*(cell.depth-d-1)))&3);}}if occupied.count_ones()<2{return false;}}
    for rotated in [false,true]{let mut order=[0usize;MAX_CELLS];for i in 0..c{order[i]=i;}if rotated{order[..c].sort_by_key(|&i|cells[i].alt_lo);}let mut rank=[0usize;MAX_CELLS];for i in 0..c{rank[order[i]]=i;}for i in 0..n{if edges[i].negative==rotated&&rank[endpoints[i][0]]>rank[endpoints[i][1]]{return false;}}}
    masks.fill(0);if !run_sweep(&cells,c,&edges,n,&endpoints,false,masks)||!run_sweep(&cells,c,&edges,n,&endpoints,true,masks){return false;}*cell_count=c;true
}

#[no_mangle]
pub unsafe extern "C" fn k_quadtree_edge_distribution(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_WORDS { return -1; }
    let values=unsafe{core::slice::from_raw_parts(input,length)};
    let mut masks=[0u64;MAX_CELLS];let mut c=0usize;
    if !parse_and_run(values,&mut masks,&mut c){return -1;}
    let bytes=8*(1+c);if output.is_null()||capacity<bytes{return -2;}
    let out=unsafe{core::slice::from_raw_parts_mut(output,bytes)};
    for shift in 0..8{out[shift]=((c as u64)>>(8*shift)) as u8;}
    for (i,word) in masks[..c].iter().enumerate(){
        for shift in 0..8{out[8*(i+1)+shift]=(*word>>(8*shift)) as u8;}
    }
    bytes as i64
}
