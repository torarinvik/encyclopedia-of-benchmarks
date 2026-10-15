const MAX_OPS: usize = 32;
const POOL_CAP: usize = 8192;
const OUT_I64_CAP: usize = 5000;
#[derive(Clone, Copy)]
struct Node { value: i64, left: usize, right: usize, height: i64 }
const EMPTY: Node = Node { value: 0, left: 0, right: 0, height: -1 };
fn height(pool: &[Node; POOL_CAP], id: usize) -> i64 { pool[id].height }
fn make_node(pool: &mut [Node; POOL_CAP], next: &mut usize, value: i64, left: usize, right: usize) -> usize {
    let id=*next;*next+=1;pool[id]=Node{value,left,right,height:1+height(pool,left).max(height(pool,right))};id
}
fn balance(pool:&[Node;POOL_CAP],id:usize)->i64{height(pool,pool[id].right)-height(pool,pool[id].left)}
fn rotate_right(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize)->usize{let left=pool[root].left;let moved=make_node(pool,next,pool[root].value,pool[left].right,pool[root].right);make_node(pool,next,pool[left].value,pool[left].left,moved)}
fn rotate_left(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize)->usize{let right=pool[root].right;let moved=make_node(pool,next,pool[root].value,pool[root].left,pool[right].left);make_node(pool,next,pool[right].value,moved,pool[right].right)}
fn rebalance(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize)->usize{let bf=balance(pool,root);if bf>1{if balance(pool,pool[root].right)<0{let rotated=rotate_right(pool,next,pool[root].right);let nr=make_node(pool,next,pool[root].value,pool[root].left,rotated);return rotate_left(pool,next,nr);}return rotate_left(pool,next,root);}if bf< -1{if balance(pool,pool[root].left)>0{let rotated=rotate_left(pool,next,pool[root].left);let nr=make_node(pool,next,pool[root].value,rotated,pool[root].right);return rotate_right(pool,next,nr);}return rotate_right(pool,next,root);}root}
fn insert_node(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize,value:i64)->usize{if root==0{return make_node(pool,next,value,0,0);}let n=pool[root];if value==n.value{return root;}if value<n.value{let l=insert_node(pool,next,n.left,value);let nr=make_node(pool,next,n.value,l,n.right);rebalance(pool,next,nr)}else{let r=insert_node(pool,next,n.right,value);let nr=make_node(pool,next,n.value,n.left,r);rebalance(pool,next,nr)}}
fn delete_min(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize,minimum:&mut i64)->usize{let n=pool[root];if n.left==0{*minimum=n.value;return n.right;}let l=delete_min(pool,next,n.left,minimum);let nr=make_node(pool,next,n.value,l,n.right);rebalance(pool,next,nr)}
fn delete_node(pool:&mut[Node;POOL_CAP],next:&mut usize,root:usize,value:i64)->usize{if root==0{return 0;}let n=pool[root];if value<n.value{let l=delete_node(pool,next,n.left,value);let nr=make_node(pool,next,n.value,l,n.right);return rebalance(pool,next,nr);}if value>n.value{let r=delete_node(pool,next,n.right,value);let nr=make_node(pool,next,n.value,n.left,r);return rebalance(pool,next,nr);}if n.left==0{return n.right;}if n.right==0{return n.left;}let mut successor=0;let r=delete_min(pool,next,n.right,&mut successor);let nr=make_node(pool,next,successor,n.left,r);rebalance(pool,next,nr)}

#[no_mangle]
pub unsafe extern "C" fn avltree_persistent_insert_delete(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1{return -1;}let values=std::slice::from_raw_parts(input,length);if !(0..=MAX_OPS as i64).contains(&values[0])||length!=1+3*values[0] as usize{return -1;}let ops=values[0] as usize;
    for i in 0..ops{let p=values[1+3*i];let op=values[2+3*i];let v=values[3+3*i];if p<0||p>i as i64||(op!=0&&op!=1)||!(-1000..=1000).contains(&v){return -1;}}
    let mut pool=[EMPTY;POOL_CAP];let mut next=1;let mut roots=[0_usize;MAX_OPS+1];for i in 0..ops{let root=roots[values[1+3*i] as usize];roots[i+1]=if values[2+3*i]==0{insert_node(&mut pool,&mut next,root,values[3+3*i])}else{delete_node(&mut pool,&mut next,root,values[3+3*i])};if next>=POOL_CAP-64{return -1;}}
    let mut packed=[0_i64;OUT_I64_CAP];let mut used=0;packed[used]=ops as i64+1;used+=1;
    for ver in 0..=ops{let root=roots[ver];let mut queue=[0_usize;MAX_OPS+1];let mut local=vec![-1_i32;POOL_CAP];let mut left_id=[-1_i32;MAX_OPS+1];let mut right_id=[-1_i32;MAX_OPS+1];let mut tail=0;if root!=0{queue[0]=root;local[root]=0;tail=1;}for head in 0..tail{let children=[pool[queue[head]].left,pool[queue[head]].right];for side in 0..2{let child=children[side];if child!=0{if local[child]<0{local[child]=tail as i32;queue[tail]=child;tail+=1;}if side==0{left_id[head]=local[child];}else{right_id[head]=local[child];}}}}packed[used]=tail as i64;used+=1;packed[used]=height(&pool,root);used+=1;for i in 0..tail{let n=pool[queue[i]];for val in [n.value,n.height,left_id[i] as i64,right_id[i] as i64]{packed[used]=val;used+=1;}}}
    let required=used*8;if output.is_null()||capacity<required{return -2;}let bytes=std::slice::from_raw_parts_mut(output,required);for(i,&v)in packed[..used].iter().enumerate(){for b in 0..8_usize{bytes[i*8+b]=(v as u64>>(8*b))as u8;}}required as i64
}
