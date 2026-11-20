use std::slice;

const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const INPUT_MAX: usize = 93;

fn connected(adj: &[[bool; N]; N], n: usize, removed: isize) -> bool {
    let start = if removed == 0 { 1 } else { 0 };
    let mut seen = [false; N];
    let mut stack = [0_usize; N];
    let (mut top, mut count) = (1, 0);
    seen[start] = true; stack[0] = start;
    while top > 0 {
        top -= 1;
        let u = stack[top]; count += 1;
        for v in 0..n {
            if v as isize != removed && adj[u][v] && !seen[v] {
                seen[v] = true; stack[top] = v; top += 1;
            }
        }
    }
    count == n - (if removed >= 0 { 1 } else { 0 })
}

fn three_outer_paths(adj: &[[bool; N]; N], outer: &[bool; N], n: usize, root: usize) -> bool {
    let mut residual = [[0_i32; 2 * N + 2]; 2 * N + 2];
    let source = 2 * n; let sink = source + 1; let nodes = sink + 1;
    for v in 0..n { if v != root { residual[2*v][2*v+1] = 1; } }
    for u in 0..n { for v in u + 1..n {
        if !adj[u][v] { continue; }
        if u == root { residual[source][2*v] += 1; }
        else if v == root { residual[source][2*u] += 1; }
        else { residual[2*u+1][2*v] += 1; residual[2*v+1][2*u] += 1; }
    }}
    for v in 0..n { if outer[v] && v != root { residual[2*v+1][sink] += 1; } }
    for _ in 0..3 {
        let mut parent = [-1_i32; 2 * N + 2];
        let mut queue = [0_usize; 2 * N + 2];
        let (mut head, mut tail) = (0, 1);
        parent[source] = source as i32; queue[0] = source;
        while head < tail && parent[sink] < 0 {
            let u = queue[head]; head += 1;
            for v in 0..nodes {
                if residual[u][v] > 0 && parent[v] < 0 {
                    parent[v] = u as i32; queue[tail] = v; tail += 1;
                    if v == sink { break; }
                }
            }
        }
        if parent[sink] < 0 { return false; }
        let mut v = sink;
        while v != source {
            let u = parent[v] as usize;
            residual[u][v] -= 1; residual[v][u] += 1; v = u;
        }
    }
    true
}

fn condition_three(inner: &[[bool; N]; N], degree: &[usize; N], n: usize) -> bool {
    let mut mask_size = [0_u8; 1 << N];
    for mask in 1..(1 << n) { mask_size[mask] = mask_size[mask >> 1] + (mask & 1) as u8; }
    for start in 0..n {
        let mut dp = [[u8::MAX; N]; 1 << N];
        dp[1 << start][start] = if degree[start] >= 3 { 1 } else { 0 };
        for mask in 0..(1 << n) {
            if mask & (1 << start) == 0 { continue; }
            for last in start..n {
                let used = dp[mask][last];
                if used == u8::MAX { continue; }
                if mask_size[mask] >= 3 && inner[last][start] && used < 3 { return false; }
                for next in start + 1..n {
                    let bit = 1 << next;
                    if mask & bit != 0 || !inner[last][next] { continue; }
                    let candidate = used + if degree[next] >= 3 { 1 } else { 0 };
                    let next_mask = mask | bit;
                    if candidate < dp[next_mask][next] { dp[next_mask][next] = candidate; }
                }
            }
        }
    }
    true
}

fn compute(values: &[i64]) -> i64 {
    if !(5..=INPUT_MAX).contains(&values.len()) { return -1; }
    let (n0,m0,f0,outer0,sides0) = (values[0],values[1],values[2],values[3],values[4]);
    if !(3..=N as i64).contains(&n0) || m0 < n0 || m0 > M as i64 || m0 > 3*n0-6 ||
       !(2..=F as i64).contains(&f0) || f0 != m0-n0+2 || outer0 < 0 || outer0 >= f0 || sides0 < 3 || sides0 > n0 { return -1; }
    let (n,m,f,outer_id,side_count) = (n0 as usize,m0 as usize,f0 as usize,outer0 as usize,sides0 as usize);
    let mut adj = [[false;N];N];
    let mut edge_u = [0_usize;M]; let mut edge_v = [0_usize;M];
    let mut p = 5;
    for e in 0..m {
        if p + 2 > values.len() { return -1; }
        let (u0,v0)=(values[p],values[p+1]); p += 2;
        if u0 < 0 || u0 >= v0 || v0 >= n0 { return -1; }
        let (u,v)=(u0 as usize,v0 as usize);
        if adj[u][v] || (e>0 && (u<edge_u[e-1] || (u==edge_u[e-1] && v<=edge_v[e-1]))) { return -1; }
        adj[u][v]=true; adj[v][u]=true; edge_u[e]=u; edge_v[e]=v;
    }
    let mut faces=[[0_usize;N];F]; let mut widths=[0_usize;F]; let mut darts=[[0_usize;N];N];
    for face in 0..f {
        if p>=values.len() { return -1; }
        let w0=values[p]; p+=1;
        if w0<3 || w0>n0 || p+w0 as usize>values.len() { return -1; }
        let width=w0 as usize; widths[face]=width; let mut row=[false;N];
        for i in 0..width {
            let x0=values[p]; p+=1;
            if x0<0 || x0>=n0 || row[x0 as usize] { return -1; }
            let x=x0 as usize; row[x]=true; faces[face][i]=x;
        }
        for i in 0..width { let u=faces[face][i]; let v=faces[face][(i+1)%width]; if !adj[u][v] { return -1; } darts[u][v]+=1; }
    }
    if p+side_count != values.len() { return -1; }
    let mut apex=[0_usize;N];
    for i in 0..side_count {
        let pos=values[p]; p+=1;
        if pos<0 || pos>=widths[outer_id] as i64 || (i>0 && pos<=apex[i-1] as i64) { return -1; }
        apex[i]=pos as usize;
    }
    for e in 0..m { if darts[edge_u[e]][edge_v[e]]!=1 || darts[edge_v[e]][edge_u[e]]!=1 { return -1; } }
    if !connected(&adj,n,-1) || (0..n).any(|v| !connected(&adj,n,v as isize)) { return -1; }
    let mut link_adj=[[[false;N];N];N]; let mut link_degree=[[0_usize;N];N];
    for face in 0..f { for i in 0..widths[face] {
        let center=faces[face][i]; let before=faces[face][(i+widths[face]-1)%widths[face]]; let after=faces[face][(i+1)%widths[face]];
        if before==after { return -1; }
        link_adj[center][before][after]=true; link_adj[center][after][before]=true;
        link_degree[center][before]+=1; link_degree[center][after]+=1;
    }}
    for center in 0..n {
        let mut seed=None; let mut incident=0;
        for v in 0..n { if adj[center][v] { if link_degree[center][v]!=2 { return -1; } if seed.is_none(){seed=Some(v);} incident+=1; } else if link_degree[center][v]!=0{return -1;} }
        let start=match seed {Some(v)=>v,None=>return -1};
        let mut seen=[false;N]; let mut stack=[0_usize;N]; let (mut top,mut reached)=(1,0); seen[start]=true; stack[0]=start;
        while top>0 { top-=1; let v=stack[top]; reached+=1; for w in 0..n { if link_adj[center][v][w]&&!seen[w] {seen[w]=true;stack[top]=w;top+=1;} } }
        if reached!=incident{return -1;}
    }
    let mut outer_v=[false;N]; let mut outer_e=[[false;N];N];
    for i in 0..widths[outer_id] {let u=faces[outer_id][i];let v=faces[outer_id][(i+1)%widths[outer_id]];outer_v[u]=true;outer_e[u][v]=true;outer_e[v][u]=true;}
    let mut face_a=[usize::MAX;M];let mut face_b=[usize::MAX;M];let mut face_count=[0_usize;M];
    for face in 0..f {for i in 0..widths[face] {let u=faces[face][i];let v=faces[face][(i+1)%widths[face]];let(lo,hi)=if u<v{(u,v)}else{(v,u)};let e=match (0..m).find(|&e|edge_u[e]==lo&&edge_v[e]==hi) {Some(e)=>e,None=>return -1};if face_count[e]>=2{return -1;}if face_count[e]==0{face_a[e]=face;}else{face_b[e]=face;}face_count[e]+=1;}}
    for e in 0..m {if face_count[e]!=2||face_a[e]==face_b[e]{return -1;}}
    let mut sides=[[false;N];N];
    for s in 0..side_count {let mut at=apex[s];let end=apex[(s+1)%side_count];loop{sides[s][faces[outer_id][at]]=true;if at==end{break;}at=(at+1)%widths[outer_id];}}
    let mut degree=[0_usize;N];for u in 0..n{degree[u]=adj[u][..n].iter().filter(|&&x|x).count();}
    for root in 0..n {if !outer_v[root]&&degree[root]>=3&&!three_outer_paths(&adj,&outer_v,n,root){return 0;}}
    let mut seen_inner=[false;N];
    for seed in 0..n {if outer_v[seed]||seen_inner[seed]{continue;}let mut border=[false;N];let mut stack=[0_usize;N];let mut top=1;seen_inner[seed]=true;stack[0]=seed;while top>0{top-=1;let u=stack[top];for v in 0..n{if !adj[u][v]{continue;}if outer_v[v]{border[v]=true;}else if !seen_inner[v]{seen_inner[v]=true;stack[top]=v;top+=1;}}}for s in 0..side_count{let mut nonempty=false;let mut contained=true;for v in 0..n{if border[v]{nonempty=true;if !sides[s][v]{contained=false;}}}if nonempty&&contained{return 0;}}}
    for e in 0..m {let u=edge_u[e];let v=edge_v[e];if !outer_e[u][v]{for s in 0..side_count{if sides[s][u]&&sides[s][v]{return 0;}}}}
    let mut inner=[[false;N];N];for e in 0..m{let u=edge_u[e];let v=edge_v[e];if !outer_e[u][v]{inner[u][v]=true;inner[v][u]=true;}}
    if condition_three(&inner,&degree,n){1}else{0}
}

#[no_mangle]
pub unsafe extern "C" fn thomassen_convex_drawing_extendibility(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > INPUT_MAX { return -1; }
    let values = unsafe { slice::from_raw_parts(input,length) };
    compute(values)
}
