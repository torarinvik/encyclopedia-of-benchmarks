const MAX_CELLS: usize = 400;
const INF: i32 = 1_000_000;
fn h(a: usize, b: usize, cols: usize) -> i32 {
    let dy = (a / cols) as i32 - (b / cols) as i32;
    let dx = (a % cols) as i32 - (b % cols) as i32;
    ((dy * dy + dx * dx) as f64).sqrt() as i32
}
unsafe fn put(out: *mut u8, slot: usize, value: i64) { let bits=value as u64; for i in 0..8 { *out.add(slot*8+i)=(bits>>(i*8)) as u8; } }
#[no_mangle]
pub unsafe extern "C" fn bidirectional_a_star(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<6 { return -1; }
    let a=std::slice::from_raw_parts(input,length); if a[0]<1||a[0]>20||a[1]<1||a[1]>20{return -1;}
    let (rows,cols)=(a[0] as usize,a[1] as usize);let cells=rows*cols;
    if a[2]<0||a[2]>=rows as i64||a[3]<0||a[3]>=cols as i64||a[4]<0||a[4]>=rows as i64||a[5]<0||a[5]>=cols as i64||length!=6+cells{return -1;}
    let (start,goal)=(a[2] as usize*cols+a[3] as usize,a[4] as usize*cols+a[5] as usize);let mut blocked=[false;MAX_CELLS];
    for i in 0..cells { if a[6+i]!=0&&a[6+i]!=1{return -1;} blocked[i]=a[6+i]==1; } if blocked[start]||blocked[goal]{return -1;}
    let mut g=[[INF;MAX_CELLS];2];let mut parent=[[-1i32;MAX_CELLS];2];let mut order=[[0i32;MAX_CELLS];2];let mut opened=[[false;MAX_CELLS];2];let mut closed=[[false;MAX_CELLS];2];let mut seq=[0i32;2];
    g[0][start]=0;g[1][goal]=0;opened[0][start]=true;opened[1][goal]=true;order[0][start]=0;order[1][goal]=0;seq=[1,1];let dirs=[(-1i32,0i32),(0,-1),(1,0),(0,1)];let mut best=INF;let mut meet:Option<usize>=None;
    loop { let mut mg=[INF;2];for s in 0..2{for v in 0..cells{if opened[s][v]&&g[s][v]<mg[s]{mg[s]=g[s][v];}}}if best<INF&&(mg[0]==INF||mg[1]==INF||mg[0]+mg[1]>=best){break;}
      for s in 0..2 {let target=if s==0{goal}else{start};let mut chosen=None;let mut bf=INF;for v in 0..cells{if opened[s][v]{let f=g[s][v]+h(v,target,cols);if chosen.is_none()||f<bf||(f==bf&&order[s][v]<order[s][chosen.unwrap()]){chosen=Some(v);bf=f;}}}let Some(u)=chosen else{continue};opened[s][u]=false;closed[s][u]=true;if g[1-s][u]<INF&&g[s][u]+g[1-s][u]<best{best=g[s][u]+g[1-s][u];meet=Some(u);}
        let (y,x)=((u/cols) as i32,(u%cols) as i32);for (dy,dx) in dirs{let ny=y+dy;let nx=x+dx;if ny<0||ny>=rows as i32||nx<0||nx>=cols as i32{continue;}let v=ny as usize*cols+nx as usize;if blocked[v]||closed[s][v]{continue;}let ng=g[s][u]+1;if ng<g[s][v]{g[s][v]=ng;parent[s][v]=u as i32;opened[s][v]=true;order[s][v]=seq[s];seq[s]+=1;if g[1-s][v]<INF&&ng+g[1-s][v]<best{best=ng+g[1-s][v];meet=Some(v);}}}
      }
      if !opened[0].iter().chain(opened[1].iter()).any(|&x|x){break;}
    }
    let mut path=[0usize;MAX_CELLS];let mut count=0;if let Some(m)=meet{let mut rev=[0usize;MAX_CELLS];let mut n=0;let mut v=m as i32;while v>=0{rev[n]=v as usize;n+=1;v=parent[0][v as usize];}while n>0{n-=1;path[count]=rev[n];count+=1;}let mut v=parent[1][m];while v>=0{path[count]=v as usize;count+=1;v=parent[1][v as usize];}}else{path[0]=start;count=1;}
    let bytes=(1+2*count)*8;if output.is_null()||capacity<bytes{return -2;}put(output,0,count as i64);for i in 0..count{put(output,1+2*i,(path[i]/cols) as i64);put(output,2+2*i,(path[i]%cols) as i64);}bytes as i64
}
