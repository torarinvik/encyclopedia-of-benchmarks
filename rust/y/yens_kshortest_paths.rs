#[derive(Clone, Copy)]
struct Path { len: usize, nodes: [i64; 8], cost: i64 }
fn less(a: Path, b: Path) -> bool {
    if a.cost != b.cost { return a.cost < b.cost; }
    for i in 0..a.len.min(b.len) { if a.nodes[i] != b.nodes[i] { return a.nodes[i] < b.nodes[i]; } }
    a.len < b.len
}
fn same(a: Path,b: Path)->bool { a.len==b.len && (0..a.len).all(|i|a.nodes[i]==b.nodes[i]) }
fn prefix(a:Path,b:Path,n:usize)->bool {a.len>=n&&b.len>=n&&(0..n).all(|i|a.nodes[i]==b.nodes[i])}
fn shortest(n:usize,src:usize,dst:usize,w:&[[i64;8];8],banv:&[bool;8],bane:&[[bool;8];8])->Option<Path>{
    let mut q=Vec::new();let mut nodes=[0i64;8];nodes[0]=src as i64;q.push(Path{len:1,nodes,cost:0});
    while !q.is_empty(){let mut best=0;for i in 1..q.len(){if less(q[i],q[best]){best=i;}}let p=q.swap_remove(best);let u=p.nodes[p.len-1] as usize;if u==dst{return Some(p)}
        for v in 0..n {if w[u][v]>=0&&!banv[v]&&!bane[u][v]&&!(0..p.len).any(|i|p.nodes[i]==v as i64){let mut t=p;t.nodes[t.len]=v as i64;t.len+=1;t.cost+=w[u][v];q.push(t);}}
    }None
}
unsafe fn put(out:*mut u8,offset:usize,value:i64){let bytes=value.to_le_bytes();for i in 0..8{*out.add(offset+i)=bytes[i];}}
#[no_mangle]
pub unsafe extern "C" fn yens_kshortest_paths(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4{return -1}let data=std::slice::from_raw_parts(input,length);let (n,k,src,dst)=(data[0],data[1],data[2],data[3]);
    if !(1..=8).contains(&n)||!(1..=8).contains(&k)||src<0||src>=n||dst<0||dst>=n||length!=4+(n*n) as usize{return -1}
    let (n,k,src,dst)=(n as usize,k as usize,src as usize,dst as usize);let mut w=[[-1i64;8];8];
    for i in 0..n{for j in 0..n{let x=data[4+i*n+j];if !(-1..=1000).contains(&x){return -1}w[i][j]=x;}}
    let mut accepted=Vec::<Path>::new();let mut candidates=Vec::<Path>::new();let mut bv=[false;8];let mut be=[[false;8];8];
    if let Some(p)=shortest(n,src,dst,&w,&bv,&be){accepted.push(p)}
    while accepted.len()<k&&!accepted.is_empty(){let prev=*accepted.last().unwrap();for i in 0..prev.len-1{
        let mut root=Path{len:i+1,nodes:[0;8],cost:0};for j in 0..=i{root.nodes[j]=prev.nodes[j];}for j in 0..i{root.cost+=w[root.nodes[j] as usize][root.nodes[j+1] as usize];}
        for p in &accepted{if prefix(*p,root,i+1)&&p.len>i+1{be[p.nodes[i] as usize][p.nodes[i+1] as usize]=true;}}
        for j in 0..i{bv[root.nodes[j] as usize]=true;}
        if let Some(spur)=shortest(n,root.nodes[i] as usize,dst,&w,&bv,&be){let mut total=root;for j in 1..spur.len{total.nodes[total.len]=spur.nodes[j];total.len+=1;}total.cost+=spur.cost;
            if !accepted.iter().any(|p|same(*p,total))&&!candidates.iter().any(|p|same(*p,total)){candidates.push(total);}}
        for j in 0..i{bv[root.nodes[j] as usize]=false;}
        for p in &accepted{if prefix(*p,root,i+1)&&p.len>i+1{be[p.nodes[i] as usize][p.nodes[i+1] as usize]=false;}}
    }if candidates.is_empty(){break}let mut best=0;for i in 1..candidates.len(){if less(candidates[i],candidates[best]){best=i;}}accepted.push(candidates.swap_remove(best));}
    let bytes=8+accepted.iter().map(|p|(p.len+2)*8).sum::<usize>();if output.is_null()||capacity<bytes{return -2}put(output,0,accepted.len() as i64);let mut at=8;
    for p in &accepted{put(output,at,p.len as i64);at+=8;for j in 0..p.len{put(output,at,p.nodes[j]);at+=8;}put(output,at,p.cost);at+=8;}bytes as i64
}
