const MAX_V: usize = 10;
const MAX_E: usize = 45;
fn dfs(u: usize, neighbors: &[[usize; MAX_E]; MAX_V], degree: &[usize; MAX_V], seen: &mut [[bool; MAX_V]; MAX_V], path: &mut [i64; MAX_E + 1], count: &mut usize) {
    path[*count] = u as i64; *count += 1;
    for i in 0..degree[u] { let v = neighbors[u][i]; if !seen[u][v] { seen[u][v] = true; seen[v][u] = true; dfs(v, neighbors, degree, seen, path, count); } }
}
unsafe fn put(out: *mut u8, slot: usize, value: i64) { let b = value as u64; for i in 0..8 { *out.add(slot * 8 + i) = (b >> (i * 8)) as u8; } }
#[no_mangle]
pub unsafe extern "C" fn eulerian_trail_undirected_simple(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let n0=*input; let m0=*input.add(1); if !(2..=MAX_V as i64).contains(&n0)||!(0..=MAX_E as i64).contains(&m0) { return -1; }
    let (n,m)=(n0 as usize,m0 as usize); if length!=2+2*m { return -1; }
    let mut neighbors=[[0usize;MAX_E];MAX_V]; let mut degree=[0usize;MAX_V]; let mut adjacent=[[false;MAX_V];MAX_V];
    for i in 0..m { let (a,b)=(*input.add(2+2*i),*input.add(3+2*i)); if a<0||b<0||a as usize>=n||b as usize>=n||a==b{return -1;} let (u,v)=(a as usize,b as usize); if adjacent[u][v]{return -1;} adjacent[u][v]=true;adjacent[v][u]=true;neighbors[u][degree[u]]=v;degree[u]+=1;neighbors[v][degree[v]]=u;degree[v]+=1; }
    let mut odd=0usize;let mut start=1usize;for v in 0..n{if degree[v]%2==1{odd+=1;start=v;}}if odd!=0&&odd!=2{return -1;}let status=if odd==0{1}else{2};if status==1{start=1;}
    if m>0 { if status==1&&degree[1]==0{return -1;} let mut reached=[false;MAX_V];let mut stack=[0usize;MAX_V];let mut top=0;stack[top]=start;top+=1;reached[start]=true;while top>0{top-=1;let u=stack[top];for i in 0..degree[u]{let v=neighbors[u][i];if !reached[v]{reached[v]=true;stack[top]=v;top+=1;}}}for v in 0..n{if degree[v]>0&&!reached[v]{return -1;}} }
    let mut seen=[[false;MAX_V];MAX_V];let mut path=[0i64;MAX_E+1];let mut count=0;dfs(start,&neighbors,&degree,&mut seen,&mut path,&mut count);if count!=m+1{return -1;}let bytes=(2+count)*8;if output.is_null()||capacity<bytes{return -2;}put(output,0,status);put(output,1,count as i64);for i in 0..count{put(output,2+i,path[i]);}bytes as i64
}
