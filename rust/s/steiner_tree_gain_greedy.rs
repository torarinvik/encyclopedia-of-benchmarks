use std::slice;

const N: usize = 4;
const MAX_INPUT: usize = 37;

#[derive(Clone, Copy)]
struct Edge { u: usize, v: usize, w: i64 }

fn put_i64(out: &mut [u8], word: usize, value: i64) {
    out[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}
fn find(p: &mut [usize; N], mut x: usize) -> usize {
    while p[x] != x { p[x] = p[p[x]]; x = p[x]; }
    x
}
fn join(p: &mut [usize; N], a: usize, b: usize) -> bool {
    let ra = find(p, a); let rb = find(p, b);
    if ra == rb { false } else { p[rb] = ra; true }
}
fn groups(n: usize, mask: i64, h: &[[bool; N]; N]) -> Vec<usize> {
    let mut p = [0usize, 1, 2, 3];
    for i in 0..n { for j in i + 1..n { if h[i][j] { join(&mut p, i, j); } } }
    let mut roots = Vec::new();
    for i in 0..n { if mask & (1 << i) != 0 {
        let r = find(&mut p, i);
        if !roots.contains(&r) { roots.push(r); }
    } }
    roots
}
fn mst_metric(n: usize, mask: i64, w: &[[i64; N]; N]) -> i64 {
    let verts: Vec<usize> = (0..n).filter(|&i| mask & (1 << i) != 0).collect();
    if verts.len() <= 1 { return 0; }
    let mut used = [false; N]; let mut best = [i64::MAX; N];
    used[verts[0]] = true;
    for &v in &verts[1..] { best[v] = w[verts[0]][v]; }
    let mut total = 0;
    for _ in 1..verts.len() {
        let v = *verts.iter().filter(|&&x| !used[x]).min_by_key(|&&x| (best[x], x)).unwrap();
        total += best[v]; used[v] = true;
        for &x in &verts { if !used[x] && w[v][x] < best[x] { best[x] = w[v][x]; } }
    }
    total
}
fn mst_h(n: usize, w: &[[i64; N]; N], h: &[[bool; N]; N]) -> (i64, Vec<Edge>) {
    let mut es = Vec::new();
    for i in 0..n { for j in i + 1..n { if h[i][j] { es.push(Edge { u:i, v:j, w:w[i][j] }); } } }
    es.sort_by_key(|e| (e.w,e.u,e.v));
    let mut p = [0usize,1,2,3]; let mut cost = 0; let mut tree = Vec::new();
    for e in es { if join(&mut p,e.u,e.v) { cost += e.w; tree.push(e); } }
    (cost,tree)
}
fn contracted_mst(n: usize, mask: i64, w: &[[i64; N]; N], h: &[[bool; N]; N]) -> i64 {
    let mut d = *w; let mut p = [0usize,1,2,3];
    for i in 0..n { for j in i+1..n { if h[i][j] { d[i][j]=0; d[j][i]=0; join(&mut p,i,j); } } }
    for k in 0..n { for i in 0..n { for j in 0..n {
        if d[i][j] > d[i][k] + d[k][j] { d[i][j] = d[i][k] + d[k][j]; }
    } } }
    let roots = groups(n, mask, h);
    if roots.len() <= 1 { return 0; }
    let members: Vec<Vec<usize>> = roots.iter().map(|&r| (0..n).filter(|&v| find(&mut p,v)==r).collect()).collect();
    let g = roots.len(); let mut q = vec![vec![0i64;g];g];
    for a in 0..g { for b in a+1..g {
        q[a][b] = members[a].iter().flat_map(|&u| members[b].iter().map(move |&v| d[u][v])).min().unwrap();
        q[b][a] = q[a][b];
    } }
    let mut used=vec![false;g]; let mut best=vec![i64::MAX;g]; used[0]=true;
    for j in 1..g { best[j]=q[0][j]; }
    let mut total=0;
    for _ in 1..g { let v=(0..g).filter(|&x| !used[x]).min_by_key(|&x|(best[x],x)).unwrap();
        total+=best[v]; used[v]=true; for x in 0..g { if !used[x] && q[v][x]<best[x] {best[x]=q[v][x];} }
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn steiner_tree_gain_greedy(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let a = slice::from_raw_parts(input,length);
    let n0=a[0]; let mask=a[1]; let count0=a[2];
    if !(2..=4).contains(&n0) || mask<=0 || mask >> n0 != 0 || !(1..=4).contains(&count0) { return -1; }
    let n=n0 as usize; let count=count0 as usize;
    if (0..n).filter(|&i| mask&(1<<i)!=0).count()<2 { return -1; }
    let mut w=[[0i64;N];N]; let mut at=3;
    for i in 0..n { for j in i+1..n { if at>=length || !(0..=1000).contains(&a[at]) {return -1;} w[i][j]=a[at];w[j][i]=a[at];at+=1; } }
    for i in 0..n { for j in 0..n { for k in 0..n {if w[i][j]>w[i][k]+w[k][j]{return -1;} } } }
    let mut family: Vec<Vec<(usize,usize)>>=Vec::new(); let mut family_h=[[false;N];N];
    for _ in 0..count {
        if at>=length {return -1;} let ec=a[at];at+=1;
        if ec<1 || ec>n0-1 || at+2*ec as usize>length {return -1;}
        let mut edges=Vec::new();let mut degree=[0usize;N];let mut p=[0usize,1,2,3];
        for _e in 0..ec {let u0=a[at];let v0=a[at+1];at+=2;
            if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0{return -1;}
            let (u,v)=(u0 as usize,v0 as usize);let e=(u.min(v),u.max(v));
            if edges.contains(&e)||!join(&mut p,u,v){return -1;} edges.push(e);degree[u]+=1;degree[v]+=1;family_h[u][v]=true;family_h[v][u]=true;
        }
        let verts:Vec<usize>=(0..n).filter(|&v|degree[v]>0).collect();
        if verts.len()!=ec as usize+1||verts.iter().any(|&v|find(&mut p,v)!=find(&mut p,verts[0])){return -1;}
        let leaves:Vec<usize>=verts.iter().copied().filter(|&v|degree[v]==1).collect();
        if !(2..=3).contains(&leaves.len())||leaves.iter().any(|&v|mask&(1<<v)==0)||verts.iter().any(|&v|mask&(1<<v)!=0&&degree[v]!=1){return -1;}
        family.push(edges);
    }
    if at!=length||groups(n,mask,&family_h).len()!=1{return -1;}
    let baseline=mst_metric(n,mask,&w);let mut h=[[false;N];N];let mut selected=[false;4];
    while groups(n,mask,&h).len()>1 {
        let before=groups(n,mask,&h).len();let mut best:Option<(usize,i64)>=None;
        for c in 0..count {if selected[c]{continue;}let mut trial=h;
            for &(u,v) in &family[c]{trial[u][v]=true;trial[v][u]=true;}
            if groups(n,mask,&trial).len()>=before{continue;}
            let (mh,_)=mst_h(n,&w,&trial);let gain=baseline-contracted_mst(n,mask,&w,&trial)-mh;
            if best.is_none()||gain>best.unwrap().1{best=Some((c,gain));}
        }
        let c=match best{Some((i,_))=>i,None=>return -1};selected[c]=true;
        for &(u,v) in &family[c]{h[u][v]=true;h[v][u]=true;}
    }
    let (cost,tree)=mst_h(n,&w,&h);let bytes=8*(3+2*tree.len());
    if output.is_null()||capacity<bytes{return -2;}
    let out=slice::from_raw_parts_mut(output,bytes);put_i64(out,0,1);put_i64(out,1,cost);put_i64(out,2,tree.len() as i64);
    for (i,e) in tree.iter().enumerate(){put_i64(out,3+2*i,e.u as i64);put_i64(out,4+2*i,e.v as i64);}
    bytes as i64
}
