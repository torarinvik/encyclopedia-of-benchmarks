package avltree_persistent_insert_delete

import "core:c"

MAX_OPS :: 32
POOL_CAP :: 8192
OUT_CAP :: 5000
Node :: struct { value, left, right, height: int }

node_height :: proc "contextless" (pool: [^]Node, id: int) -> int { if id == 0 { return -1 }; return pool[id].height }
make_node :: proc "contextless" (pool: [^]Node, next: ^int, value, left, right: int) -> int {
	id:=next^;next^+=1;pool[id]=Node{value,left,right,1+max(node_height(pool,left),node_height(pool,right))};return id
}
balance :: proc "contextless" (pool: [^]Node, id: int) -> int { return node_height(pool,pool[id].right)-node_height(pool,pool[id].left) }
rotate_right :: proc "contextless" (pool: [^]Node,next:^int,root:int)->int { left:=pool[root].left;moved:=make_node(pool,next,pool[root].value,pool[left].right,pool[root].right);return make_node(pool,next,pool[left].value,pool[left].left,moved) }
rotate_left :: proc "contextless" (pool: [^]Node,next:^int,root:int)->int { right:=pool[root].right;moved:=make_node(pool,next,pool[root].value,pool[root].left,pool[right].left);return make_node(pool,next,pool[right].value,moved,pool[right].right) }
rebalance :: proc "contextless" (pool:[^]Node,next:^int,root:int)->int {
	bf:=balance(pool,root)
	if bf>1 { if balance(pool,pool[root].right)<0 { rotated:=rotate_right(pool,next,pool[root].right);root=make_node(pool,next,pool[root].value,pool[root].left,rotated) };return rotate_left(pool,next,root) }
	if bf< -1 { if balance(pool,pool[root].left)>0 { rotated:=rotate_left(pool,next,pool[root].left);root=make_node(pool,next,pool[root].value,rotated,pool[root].right) };return rotate_right(pool,next,root) }
	return root
}
insert_node :: proc "contextless" (pool:[^]Node,next:^int,root,value:int)->int {
	if root==0 do return make_node(pool,next,value,0,0)
	if value==pool[root].value do return root
	if value<pool[root].value { left:=insert_node(pool,next,pool[root].left,value);return rebalance(pool,next,make_node(pool,next,pool[root].value,left,pool[root].right)) }
	right:=insert_node(pool,next,pool[root].right,value);return rebalance(pool,next,make_node(pool,next,pool[root].value,pool[root].left,right))
}
delete_min :: proc "contextless" (pool:[^]Node,next:^int,root:int,minimum:^int)->int {
	if pool[root].left==0 { minimum^=pool[root].value;return pool[root].right }
	left:=delete_min(pool,next,pool[root].left,minimum);return rebalance(pool,next,make_node(pool,next,pool[root].value,left,pool[root].right))
}
delete_node :: proc "contextless" (pool:[^]Node,next:^int,root,value:int)->int {
	if root==0 do return 0
	if value<pool[root].value { left:=delete_node(pool,next,pool[root].left,value);return rebalance(pool,next,make_node(pool,next,pool[root].value,left,pool[root].right)) }
	if value>pool[root].value { right:=delete_node(pool,next,pool[root].right,value);return rebalance(pool,next,make_node(pool,next,pool[root].value,pool[root].left,right)) }
	if pool[root].left==0 do return pool[root].right
	if pool[root].right==0 do return pool[root].left
	minimum:=0;right:=delete_min(pool,next,pool[root].right,&minimum);return rebalance(pool,next,make_node(pool,next,minimum,pool[root].left,right))
}
put_i64 :: proc "contextless" (output:[^]u8,offset:usize,value:i64){bits:=u64(value);for b:u32=0;b<8;b+=1{output[offset+usize(b)]=u8(bits>>(8*b))}}

@(export)
avltree_persistent_insert_delete :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<1||input[0]<0||input[0]>MAX_OPS||length!=c.size_t(1+3*input[0]) do return -1
	ops:=int(input[0]);for i:=0;i<ops;i+=1{parent,op,value:=input[1+3*i],input[2+3*i],input[3+3*i];if parent<0||parent>i||(op!=0&&op!=1)||value< -1000||value>1000 do return -1}
	var pool:[POOL_CAP]Node;next:=1;var roots:[MAX_OPS+1]int
	for i:=0;i<ops;i+=1{base:=roots[input[1+3*i]];if input[2+3*i]==0{roots[i+1]=insert_node(&pool[0],&next,base,int(input[3+3*i]))}else{roots[i+1]=delete_node(&pool[0],&next,base,int(input[3+3*i]))};if next>=POOL_CAP-64 do return -1}
	var packed:[OUT_CAP]i64;used:=0;packed[used]=i64(ops+1);used+=1
	for version:=0;version<=ops;version+=1{
		root:=roots[version];var queue:[MAX_OPS+1]int;var local:[POOL_CAP]int;var left_ids,right_ids:[MAX_OPS+1]int
		for i:=0;i<POOL_CAP;i+=1{local[i]=-1};tail:=0;if root!=0{queue[0]=root;local[root]=0;tail=1}
		for head:=0;head<tail;head+=1{left_ids[head]=-1;right_ids[head]=-1;children:=[2]int{pool[queue[head]].left,pool[queue[head]].right};for side:=0;side<2;side+=1{child:=children[side];if child!=0{if local[child]<0{local[child]=tail;queue[tail]=child;tail+=1};if side==0{left_ids[head]=local[child]}else{right_ids[head]=local[child]}}}}
		packed[used]=i64(tail);used+=1;packed[used]=i64(node_height(&pool[0],root));used+=1
		for i:=0;i<tail;i+=1{n:=pool[queue[i]];packed[used]=i64(n.value);packed[used+1]=i64(n.height);packed[used+2]=i64(left_ids[i]);packed[used+3]=i64(right_ids[i]);used+=4}
	}
	required:=usize(used*8);if output==nil||capacity<c.size_t(required) do return -2
	for i:=0;i<used;i+=1{put_i64(output,usize(i*8),packed[i])};return i64(required)
}
