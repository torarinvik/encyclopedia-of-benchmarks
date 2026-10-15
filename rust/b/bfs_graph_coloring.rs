const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 2016;
const MAX_OUTPUT_VALUES: usize = MAX_VERTICES + 2;
fn put_i64(out:&mut[u8],offset:usize,value:i64){let bits=value as u64;for b in 0..8{out[offset+b]=(bits>>(8*b))as u8;}}
#[no_mangle]
pub unsafe extern "C" fn bfs_graph_coloring(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<2{return -1;}let values=std::slice::from_raw_parts(input,length);let nv=values[0];let mv=values[1];if nv<0||nv>MAX_VERTICES as i64||mv<0||mv>MAX_EDGES as i64||length!=2+2*mv as usize{return -1;}let n=nv as usize;let m=mv as usize;
    let mut adjacency=[false;MAX_VERTICES*MAX_VERTICES];let mut degree=[0usize;MAX_VERTICES];
    for e in 0..m{let uv=values[2+2*e];let vv=values[3+2*e];if uv<0||uv>=nv||vv<0||vv>=nv||uv==vv{return -1;}let u=uv as usize;let v=vv as usize;let a=u*MAX_VERTICES+v;let b=v*MAX_VERTICES+u;if adjacency[a]{return -1;}adjacency[a]=true;adjacency[b]=true;degree[u]+=1;degree[v]+=1;}
    let mut visited=[false;MAX_VERTICES];let mut queue=[0usize;MAX_VERTICES];
    for start in 0..n{if visited[start]{continue;}let mut head=0;let mut tail=0;let mut high=0;visited[start]=true;queue[tail]=start;tail+=1;while head<tail{let vertex=queue[head];head+=1;if degree[vertex]>1{high+=1;}for nb in 0..n{if adjacency[vertex*MAX_VERTICES+nb]&&!visited[nb]{visited[nb]=true;queue[tail]=nb;tail+=1;}}}if high>1{return -1;}}
    let mut colors=[0i64;MAX_VERTICES];for c in &mut colors[..n]{*c=1;}visited.fill(false);
    for start in 0..n{if visited[start]{continue;}let mut head=0;let mut tail=0;visited[start]=true;queue[tail]=start;tail+=1;while head<tail{let front=queue[head];head+=1;for nb in 0..n{if !adjacency[front*MAX_VERTICES+nb]{continue;}if colors[nb]==colors[front]{colors[nb]+=1;}if !visited[nb]{visited[nb]=true;queue[tail]=nb;tail+=1;}}}}
    let used_colors=colors[..n].iter().copied().max().unwrap_or(0);let mut packed=[0i64;MAX_OUTPUT_VALUES];packed[0]=nv;for i in 0..n{packed[i+1]=colors[i];}packed[n+1]=used_colors;let used=n+2;let required=used*8;if output.is_null()||capacity<required{return -2;}let out=std::slice::from_raw_parts_mut(output,required);for i in 0..used{put_i64(out,8*i,packed[i]);}required as i64
}
