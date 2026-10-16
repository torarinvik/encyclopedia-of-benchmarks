const N: usize = 32;
const M: usize = 256;
const Q: usize = 64;
#[derive(Clone, Copy)]
struct Path { len: i64, nodes: [i64; N] }
fn dfs(adj: &[[i64; M]; N], degree: &[usize; N], at: usize, dest: usize, path: &mut [i64; N], depth: usize, visited: &mut [bool; N]) -> Option<usize> {
    if visited[at] { return None; }
    visited[at]=true;
    if at == dest { return Some(depth); }
    for i in 0..degree[at] { let next=adj[at][i] as usize; path[depth]=next as i64; if let Some(len)=dfs(adj,degree,next,dest,path,depth+1,visited){return Some(len);} }
    None
}
fn search(adj:&[[i64;M];N],degree:&[usize;N],mode:usize,start:usize,dest:usize)->Path{
    let mut out=Path{len:-1,nodes:[0;N]};
    if mode==0 { let mut path=[0;N];let mut visited=[false;N]; if let Some(len)=dfs(adj,degree,start,dest,&mut path,0,&mut visited){out.len=len as i64;out.nodes=path;}return out; }
    let mut parent=[usize::MAX;N];let mut queue=[0usize;N];let(mut head,mut tail)=(0,0);parent[start]=start;queue[tail]=start;tail+=1;
    while head<tail{let at=queue[head];head+=1;if at==dest{break;}for i in 0..degree[at]{let next=adj[at][i] as usize;if parent[next]==usize::MAX{parent[next]=at;queue[tail]=next;tail+=1;}}}
    if parent[dest]==usize::MAX{return out;}let mut rev=[0usize;N];let mut count=0;let mut at=dest;while at!=start{rev[count]=at;count+=1;at=parent[at];}out.len=count as i64;for i in 0..count{out.nodes[i]=rev[count-1-i] as i64;}out
}
unsafe fn put(out:*mut u8,pos:usize,value:i64){let bits=value as u64;for b in 0..8{*out.add(pos+b)=(bits>>(8*b)) as u8;}}
#[no_mangle]
pub unsafe extern "C" fn graph_swift_directed_paths(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3{return -1;}let values=std::slice::from_raw_parts(input,length);let n=values[0];let m=values[1];if n<1||n>N as i64||m<0||m>M as i64{return -1;}let qp=2+2*m as usize;if length<qp+1{return -1;}let q=values[qp];if q<1||q>Q as i64||length!=qp+1+3*q as usize{return -1;}
 let mut adj=[[0i64;M];N];let mut degree=[0usize;N];for i in 0..m as usize{let u=values[2+2*i];let v=values[3+2*i];if u<0||u>=n||v<=u||v>=n{return -1;}let u=u as usize;adj[u][degree[u]]=v;degree[u]+=1;}
 let mut modes=[0usize;Q];let mut starts=[0usize;Q];let mut dests=[0usize;Q];for i in 0..q as usize{let p=qp+1+3*i;let mode=values[p];let s=values[p+1];let d=values[p+2];if !(0..=1).contains(&mode)||s<0||s>=n||d<0||d>=n{return -1;}modes[i]=mode as usize;starts[i]=s as usize;dests[i]=d as usize;}
 let mut paths=[Path{len:-1,nodes:[0;N]};Q];let mut words=0usize;for i in 0..q as usize{paths[i]=search(&adj,&degree,modes[i],starts[i],dests[i]);words+=1+if paths[i].len>0{paths[i].len as usize}else{0};}let required=words*8;if output.is_null()||capacity<required{return -2;}let mut pos=0;for path in paths.iter().take(q as usize){put(output,pos*8,path.len);pos+=1;for node in path.nodes.iter().take(path.len.max(0) as usize){put(output,pos*8,*node);pos+=1;}}required as i64
}
