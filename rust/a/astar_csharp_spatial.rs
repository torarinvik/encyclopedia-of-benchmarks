const MAX_NODES: usize = 16;

#[derive(Clone, Copy, Default)]
struct Node { x: f64, y: f64, multiplier: f64, current: f64, estimated: f64, traversable: bool, state: i32, parent: i32 }
fn distance(a: Node, b: Node) -> f64 { ( (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) ).sqrt() }
fn total(nodes: &[Node; MAX_NODES], i: usize) -> f64 { nodes[i].current + nodes[i].estimated }
fn enqueue(heap: &mut [usize; MAX_NODES], count: &mut usize, value: usize, nodes: &[Node; MAX_NODES]) {
    let mut i=*count; *count+=1;
    while i>0 { let p=(i-1)/2; if total(nodes,heap[p])<=total(nodes,value){break;} heap[i]=heap[p];i=p; }
    heap[i]=value;
}
fn dequeue(heap: &mut [usize; MAX_NODES], count: &mut usize, nodes: &[Node; MAX_NODES]) -> usize {
    let target=heap[0]; *count-=1; let root=heap[*count]; let mut i=0;
    while i*2+1<*count { let l=i*2+1;let r=i*2+2;let child=if r<*count&&total(nodes,heap[r])<total(nodes,heap[l]){r}else{l};if total(nodes,heap[child])>=total(nodes,root){break;}heap[i]=heap[child];i=child; }
    if *count>0{heap[i]=root;} target
}
unsafe fn store_i64(out:*mut u8,offset:usize,value:i64){for(b,byte)in value.to_le_bytes().iter().enumerate(){*out.add(offset+b)=*byte;}}

#[no_mangle]
pub unsafe extern "C" fn astar_csharp_spatial(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4{return -1;} let v=std::slice::from_raw_parts(input,length);
    let(nv,mv,sv,gv)=(v[0],v[1],v[2],v[3]);if !(2..=16).contains(&nv)||mv!=nv-1||sv<0||sv>=nv||gv<0||gv>=nv{return -1;}
    let(n,m,s,g)=(nv as usize,mv as usize,sv as usize,gv as usize);if length!=4+4*n+2*m{return -1;}
    let mut nodes=[Node{parent:-1,..Node::default()};MAX_NODES];let mut parents=[0usize;MAX_NODES];let eo=4+4*n;
    for i in 0..n{let o=4+4*i;let(x,y,t,mul)=(v[o],v[o+1],v[o+2],v[o+3]);if !(-1000..=1000).contains(&x)||!(-1000..=1000).contains(&y)||(t!=0&&t!=1)||!(1..=4).contains(&mul){return -1;}nodes[i].x=x as f64;nodes[i].y=y as f64;nodes[i].traversable=t==1;nodes[i].multiplier=mul as f64;for j in 0..i{if nodes[i].x==nodes[j].x&&nodes[i].y==nodes[j].y{return -1;}}}
    for e in 0..m{let(u,w)=(v[eo+2*e],v[eo+2*e+1]);if u<0||u>=nv||w<0||w>=nv||u==w{return -1;}let(u,w)=(u as usize,w as usize);parents[w]+=1;if parents[w]>1{return -1;}for p in 0..e{if v[eo+2*p]==u as i64&&v[eo+2*p+1]==w as i64{return -1;}}}
    if parents[s]!=0{return -1;}for i in 0..n{if i!=s&&parents[i]!=1{return -1;}}
    let(mut top,mut visited)=(0usize,0usize);let mut stack=[0usize;MAX_NODES];let mut seen=[false;MAX_NODES];stack[top]=s;top+=1;while top>0{top-=1;let u=stack[top];if seen[u]{continue;}seen[u]=true;visited+=1;for e in 0..m{if v[eo+2*e]==u as i64{stack[top]=v[eo+2*e+1] as usize;top+=1;}}}if visited!=n{return -1;}
    let mut heap=[0usize;MAX_NODES];let mut hc=0usize;for e in 0..m{if v[eo+2*e]==s as i64{let u=v[eo+2*e+1] as usize;if nodes[u].traversable{nodes[u].current=distance(nodes[s],nodes[u])*nodes[u].multiplier;nodes[u].estimated=distance(nodes[u],nodes[g]);enqueue(&mut heap,&mut hc,u,&nodes);}}}
    let mut path=[0usize;MAX_NODES];let mut pc=0usize;while hc>0{let u=dequeue(&mut heap,&mut hc,&nodes);nodes[u].state=2;if total(&nodes,u)==total(&nodes,g){let mut q=g as i32;while q>=0&&pc<MAX_NODES{path[pc]=q as usize;pc+=1;q=nodes[q as usize].parent;}break;}
        for e in 0..m{if v[eo+2*e]!=u as i64{continue;}let w=v[eo+2*e+1] as usize;if !nodes[w].traversable||nodes[w].state==2{continue;}if nodes[w].state==0{nodes[w].parent=u as i32;nodes[w].current=nodes[u].current+distance(nodes[u],nodes[w])*nodes[w].multiplier;nodes[w].estimated=nodes[w].current+distance(nodes[w],nodes[g]);nodes[w].state=1;enqueue(&mut heap,&mut hc,w,&nodes);}else if total(&nodes,u)!=total(&nodes,w){let ng=nodes[u].current+distance(nodes[u],nodes[w]);let nf=ng+nodes[u].estimated;if nf<total(&nodes,w){nodes[w].parent=u as i32;nodes[w].current=ng;}}else{return -1;}}
    }
    let bytes=pc*8;if bytes==0{return 0;}if output.is_null()||capacity<bytes{return -2;}for i in 0..pc{store_i64(output,i*8,path[pc-1-i] as i64);}bytes as i64
}
