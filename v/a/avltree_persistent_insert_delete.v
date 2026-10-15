module avltree_persistent_insert_delete

const max_ops = 32
const pool_cap = 8192
const out_cap = 5000
struct Node { value int; left int; right int; height int }

fn node_height(pool []Node, id int) int { if id == 0 { return -1 }; return pool[id].height }
fn make_node(mut pool []Node, mut next int, value int, left int, right int) int {
	id:=next;next++;mut child_height:=node_height(pool,left);right_height:=node_height(pool,right);if right_height>child_height{child_height=right_height};pool[id]=Node{value,left,right,1+child_height};return id
}
fn balance(pool []Node,id int) int { return node_height(pool,pool[id].right)-node_height(pool,pool[id].left) }
fn rotate_right(mut pool []Node,mut next int,root int) int { left:=pool[root].left;moved:=make_node(mut pool,mut next,pool[root].value,pool[left].right,pool[root].right);return make_node(mut pool,mut next,pool[left].value,pool[left].left,moved) }
fn rotate_left(mut pool []Node,mut next int,root int) int { right:=pool[root].right;moved:=make_node(mut pool,mut next,pool[root].value,pool[root].left,pool[right].left);return make_node(mut pool,mut next,pool[right].value,moved,pool[right].right) }
fn rebalance(mut pool []Node,mut next int,root int) int {
	bf:=balance(pool,root)
	if bf>1 { if balance(pool,pool[root].right)<0 { rotated:=rotate_right(mut pool,mut next,pool[root].right);root=make_node(mut pool,mut next,pool[root].value,pool[root].left,rotated) };return rotate_left(mut pool,mut next,root) }
	if bf< -1 { if balance(pool,pool[root].left)>0 { rotated:=rotate_left(mut pool,mut next,pool[root].left);root=make_node(mut pool,mut next,pool[root].value,rotated,pool[root].right) };return rotate_right(mut pool,mut next,root) }
	return root
}
fn insert_node(mut pool []Node,mut next int,root int,value int) int {
	if root==0{return make_node(mut pool,mut next,value,0,0)}
	if value==pool[root].value{return root}
	if value<pool[root].value { left:=insert_node(mut pool,mut next,pool[root].left,value);return rebalance(mut pool,mut next,make_node(mut pool,mut next,pool[root].value,left,pool[root].right)) }
	right:=insert_node(mut pool,mut next,pool[root].right,value);return rebalance(mut pool,mut next,make_node(mut pool,mut next,pool[root].value,pool[root].left,right))
}
fn delete_min(mut pool []Node,mut next int,root int,mut minimum int) int {
	n:=pool[root];if n.left==0{minimum=n.value;return n.right};left:=delete_min(mut pool,mut next,n.left,mut minimum);return rebalance(mut pool,mut next,make_node(mut pool,mut next,n.value,left,n.right))
}
fn delete_node(mut pool []Node,mut next int,root int,value int) int {
	if root==0{return 0};n:=pool[root]
	if value<n.value { left:=delete_node(mut pool,mut next,n.left,value);return rebalance(mut pool,mut next,make_node(mut pool,mut next,n.value,left,n.right)) }
	if value>n.value { right:=delete_node(mut pool,mut next,n.right,value);return rebalance(mut pool,mut next,make_node(mut pool,mut next,n.value,n.left,right)) }
	if n.left==0{return n.right};if n.right==0{return n.left};mut successor:=0;right:=delete_min(mut pool,mut next,n.right,mut successor);return rebalance(mut pool,mut next,make_node(mut pool,mut next,successor,n.left,right))
}
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits>>(8*b))}}}

@[export: 'avltree_persistent_insert_delete']
pub fn avltree_persistent_insert_delete(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<1{return -1}
	unsafe {
		if input[0]<0||input[0]>max_ops||length!=usize(1+3*input[0]){return -1};ops:=int(input[0])
		for i in 0..ops{parent,op,value:=input[1+3*i],input[2+3*i],input[3+3*i];if parent<0||parent>=i64(i+1)||(op!=0&&op!=1)||value< -1000||value>1000{return -1}}
		mut pool:=[]Node{len:pool_cap};mut next:=1;mut roots:=[max_ops+1]int{}
		for i in 0..ops{base:=roots[input[1+3*i]];if input[2+3*i]==0{roots[i+1]=insert_node(mut pool,mut next,base,int(input[3+3*i]))}else{roots[i+1]=delete_node(mut pool,mut next,base,int(input[3+3*i]))};if next>=pool_cap-64{return -1}}
		mut packed:=[out_cap]i64{};mut used:=0;packed[used]=i64(ops+1);used++
		for version in 0..ops+1{root:=roots[version];mut queue:=[max_ops+1]int{};mut local:=[pool_cap]int{};mut left_ids:=[max_ops+1]int{};mut right_ids:=[max_ops+1]int{};for i in 0..pool_cap{local[i]=-1};mut tail:=0;if root!=0{queue[0]=root;local[root]=0;tail=1}
			for head in 0..tail{left_ids[head]=-1;right_ids[head]=-1;children:=[2]int{pool[queue[head]].left,pool[queue[head]].right};for side in 0..2{child:=children[side];if child!=0{if local[child]<0{local[child]=tail;queue[tail]=child;tail++};if side==0{left_ids[head]=local[child]}else{right_ids[head]=local[child]}}}}
			packed[used]=i64(tail);used++;packed[used]=i64(node_height(pool,root));used++;for i in 0..tail{n:=pool[queue[i]];packed[used]=i64(n.value);packed[used+1]=i64(n.height);packed[used+2]=i64(left_ids[i]);packed[used+3]=i64(right_ids[i]);used+=4}
		}
		required:=used*8;if unsafe{output==nil}||capacity<required{return -2};for i in 0..used{put_i64(mut output,8*i,packed[i])};return i64(required)
	}
}
