const MAX_OPS: usize = 128;
const MAX_NODES: usize = MAX_OPS + 1;
#[derive(Clone, Copy)]
struct Node { key: i32, priority: i64, left: usize, right: usize }
const EMPTY: Node = Node { key: 0, priority: 0, left: 0, right: 0 };
fn priority_for(key: i32) -> i64 { ((key as i64 + 1_000_000) * 1_103_515_245 + 12_345) % 2_147_483_648 }
fn contains(nodes: &[Node; MAX_NODES], root: usize, key: i32) -> bool { if root == 0 { false } else if key == nodes[root].key { true } else { contains(nodes, if key < nodes[root].key { nodes[root].left } else { nodes[root].right }, key) } }
fn rotate_right(nodes: &mut [Node; MAX_NODES], root: usize) -> usize { let p=nodes[root].left;nodes[root].left=nodes[p].right;nodes[p].right=root;p }
fn rotate_left(nodes: &mut [Node; MAX_NODES], root: usize) -> usize { let p=nodes[root].right;nodes[root].right=nodes[p].left;nodes[p].left=root;p }
fn insert_node(nodes: &mut [Node; MAX_NODES], next: &mut usize, root: usize, key: i32) -> usize {
    if root == 0 { let id=*next;*next+=1;nodes[id]=Node{key,priority:priority_for(key),left:0,right:0};return id; }
    if key==nodes[root].key{return root;}
    if key<nodes[root].key{let child=insert_node(nodes,next,nodes[root].left,key);nodes[root].left=child;if nodes[child].priority>nodes[root].priority{return rotate_right(nodes,root);}}
    else{let child=insert_node(nodes,next,nodes[root].right,key);nodes[root].right=child;if nodes[child].priority>nodes[root].priority{return rotate_left(nodes,root);}}
    root
}
fn merge(nodes:&mut[Node;MAX_NODES],left:usize,right:usize)->usize{if left==0{return right;}if right==0{return left;}if nodes[left].priority>nodes[right].priority{let child=merge(nodes,nodes[left].right,right);nodes[left].right=child;left}else{let child=merge(nodes,left,nodes[right].left);nodes[right].left=child;right}}
fn erase_node(nodes:&mut[Node;MAX_NODES],root:usize,key:i32)->usize{if key<nodes[root].key{let child=erase_node(nodes,nodes[root].left,key);nodes[root].left=child;root}else if key>nodes[root].key{let child=erase_node(nodes,nodes[root].right,key);nodes[root].right=child;root}else{merge(nodes,nodes[root].left,nodes[root].right)}}
fn put_i64(out:&mut[u8],offset:usize,value:i64){let bits=value as u64;for b in 0..8{out[offset+b]=(bits>>(8*b))as u8;}}
#[no_mangle]
pub unsafe extern "C" fn treap_unique_key_set(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1{return -1;}let values=std::slice::from_raw_parts(input,length);if values[0]<0||values[0]>MAX_OPS as i64||length!=1+2*values[0]as usize{return -1;}let ops=values[0]as usize;
    for i in 0..ops{let op=values[1+2*i];let key=values[2+2*i];if(op!=0&&op!=1)||!(-1_000_000..=1_000_000).contains(&key){return -1;}}
    let mut nodes=[EMPTY;MAX_NODES];let mut next=1;let mut root=0;
    for i in 0..ops{let op=values[1+2*i]as i32;let key=values[2+2*i]as i32;let present=contains(&nodes,root,key);if(op==0&&present)||(op==1&&!present){return -1;}root=if op==0{insert_node(&mut nodes,&mut next,root,key)}else{erase_node(&mut nodes,root,key)};}
    let mut stack=[0usize;MAX_OPS];let mut top=0;let mut current=root;let mut sorted=[0i64;MAX_OPS];let mut count=0;
    while current!=0||top>0{while current!=0{stack[top]=current;top+=1;current=nodes[current].left;}top-=1;current=stack[top];sorted[count]=nodes[current].key as i64;count+=1;current=nodes[current].right;}
    let required=count*8;if output.is_null()||capacity<required{return -2;}let out=std::slice::from_raw_parts_mut(output,required);for i in 0..count{put_i64(out,8*i,sorted[i]);}count as i64
}
