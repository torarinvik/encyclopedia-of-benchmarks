const K: usize = 16;
const Q: usize = 16;
const NN: usize = 31;
const OUT: usize = 174;
#[derive(Clone, Copy)] struct Node { bit: i64, left: i64, right: i64, key: i64, low: u32, high: u32, leaves: usize }
impl Node { const EMPTY: Self = Self { bit: -1, left: -1, right: -1, key: 0, low: 0, high: 0, leaves: 0 }; }
fn build(lo: usize, hi: usize, width: usize, keys: &[u32], nodes: &mut [Node; NN], used: &mut usize) -> usize {
    let id=*used; *used+=1;
    if hi-lo==1 { nodes[id]=Node{bit:-1,left:-1,right:-1,key:keys[lo] as i64,low:keys[lo],high:keys[lo],leaves:1}; return id; }
    let diff=keys[lo]^keys[hi-1]; let bit=width-(32-diff.leading_zeros() as usize);
    let split=(lo..hi).find(|&i| ((keys[i]>>(width-1-bit))&1)!=0).unwrap_or(hi);
    let left=build(lo,split,width,keys,nodes,used); let right=build(split,hi,width,keys,nodes,used);
    nodes[id]=Node{bit:bit as i64,left:left as i64,right:right as i64,key:-1,low:keys[lo],high:keys[hi-1],leaves:nodes[left].leaves+nodes[right].leaves}; id
}
fn rank_key(query:u32,width:usize,nodes:&[Node;NN])->usize {
    let mut id=0usize;let mut rank=0usize;
    loop { let node=nodes[id]; if query<node.low{return rank;} if query>node.high{return rank+node.leaves;} if node.bit<0{return rank;} let shift=width-1-node.bit as usize;if (query>>shift)&1!=0 {rank+=nodes[node.left as usize].leaves;id=node.right as usize;} else {id=node.left as usize;} }
}
unsafe fn put(out:*mut u8,pos:usize,x:i64){for b in 0..8{*out.add(pos+b)=(x as u64>>(8*b)) as u8;}}
#[no_mangle]
pub unsafe extern "C" fn mmpfh_compacted_trie_rank(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>35{return -1;}
    let w=*input;let d=*input.add(1);let q=*input.add(2);
    if !(1..=16).contains(&w)||!(1..=16).contains(&d)||!(1..=16).contains(&q)||length!=3+(d+q) as usize{return -1;}
    let limit=1u32<<(w as u32);let mut keys=[0u32;K];
    for i in 0..d as usize{let x=*input.add(3+i);if x<0||x as u64>=limit as u64||(i>0&&x<=*input.add(2+i)){return -1;}keys[i]=x as u32;}
    for i in 0..q as usize{let x=*input.add(3+d as usize+i);if x<0||x as u64>=limit as u64{return -1;}}
    let mut nodes=[Node::EMPTY;NN];let mut node_used=0;build(0,d as usize,w as usize,&keys,&mut nodes,&mut node_used);
    let mut staged=[0i64;OUT];let mut used=0;staged[used]=d;used+=1;staged[used]=node_used as i64;used+=1;staged[used]=q;used+=1;
    for node in nodes.iter().take(node_used){staged[used]=node.bit;used+=1;staged[used]=node.left;used+=1;staged[used]=node.right;used+=1;staged[used]=node.low as i64;used+=1;staged[used]=node.high as i64;used+=1;}
    for i in 0..q as usize{staged[used]=rank_key(*input.add(3+d as usize+i) as u32,w as usize) as i64;used+=1;}
    let required=used*8;if output.is_null()||capacity<required{return -2;}for i in 0..used{put(output,i*8,staged[i]);}required as i64
}
