module treap_unique_key_set

import core:c

const max_ops = 128
const max_nodes = max_ops + 1
struct Node { key int; priority i64; left int; right int }
fn priority_for(key int) i64 { return (i64(key + 1_000_000) * 1_103_515_245 + 12_345) % 2_147_483_648 }
fn contains(nodes []Node, root int, key int) bool {
	if root == 0 { return false }; if key == nodes[root].key { return true }
	if key < nodes[root].key { return contains(nodes,nodes[root].left,key) }; return contains(nodes,nodes[root].right,key)
}
fn rotate_right(mut nodes []Node, root int) int { p:=nodes[root].left;nodes[root].left=nodes[p].right;nodes[p].right=root;return p }
fn rotate_left(mut nodes []Node, root int) int { p:=nodes[root].right;nodes[root].right=nodes[p].left;nodes[p].left=root;return p }
fn insert_node(mut nodes []Node, mut next int, root int, key int) int {
	if root==0 { id:=next;next++;nodes[id]=Node{key,priority_for(key),0,0};return id }
	if key==nodes[root].key{return root}
	if key<nodes[root].key { child:=insert_node(mut nodes,mut next,nodes[root].left,key);nodes[root].left=child;if nodes[child].priority>nodes[root].priority{return rotate_right(mut nodes,root)} }
	else { child:=insert_node(mut nodes,mut next,nodes[root].right,key);nodes[root].right=child;if nodes[child].priority>nodes[root].priority{return rotate_left(mut nodes,root)} }
	return root
}
fn merge(mut nodes []Node,left int,right int) int {
	if left==0{return right};if right==0{return left}
	if nodes[left].priority>nodes[right].priority {nodes[left].right=merge(mut nodes,nodes[left].right,right);return left}
	nodes[right].left=merge(mut nodes,left,nodes[right].left);return right
}
fn erase_node(mut nodes []Node,root int,key int) int {
	if key<nodes[root].key {nodes[root].left=erase_node(mut nodes,nodes[root].left,key);return root}
	if key>nodes[root].key {nodes[root].right=erase_node(mut nodes,nodes[root].right,key);return root}
	return merge(mut nodes,nodes[root].left,nodes[root].right)
}
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits>>(8*b))}}}

@[export: 'treap_unique_key_set']
pub fn treap_unique_key_set(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<1{return -1}
	unsafe {
		if input[0]<0||input[0]>max_ops||length!=usize(1+2*input[0]){return -1};ops:=int(input[0])
		for i in 0..ops {op,key:=input[1+2*i],input[2+2*i];if (op!=0&&op!=1)||key< -1_000_000||key>1_000_000{return -1}}
		mut nodes:=[]Node{len:max_nodes};mut next:=1;mut root:=0
		for i in 0..ops {op:=int(input[1+2*i]);key:=int(input[2+2*i]);present:=contains(nodes,root,key);if (op==0&&present)||(op==1&&!present){return -1};if op==0{root=insert_node(mut nodes,mut next,root,key)}else{root=erase_node(mut nodes,root,key)}}
		mut stack:=[max_ops]int{};mut sorted:=[max_ops]i64{};mut top:=0;mut current:=root;mut count:=0
		for current!=0||top>0 {for current!=0{stack[top]=current;top++;current=nodes[current].left};top--;current=stack[top];sorted[count]=i64(nodes[current].key);count++;current=nodes[current].right}
		required:=count*8;if unsafe{output==nil}||capacity<required{return -2};for i in 0..count{put_i64(mut output,i*8,sorted[i])};return i64(count)
	}
}
