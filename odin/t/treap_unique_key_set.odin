package treap_unique_key_set

import "core:c"

MAX_OPS :: 128
MAX_NODES :: MAX_OPS + 1
Node :: struct { key: int, priority: i64, left: int, right: int }

priority_for :: proc "contextless" (key: int) -> i64 { return (i64(key + 1_000_000) * 1_103_515_245 + 12_345) % 2_147_483_648 }
contains :: proc "contextless" (nodes: [^]Node, root: int, key: int) -> bool {
	if root == 0 { return false }; if key == nodes[root].key { return true }
	if key < nodes[root].key { return contains(nodes,nodes[root].left,key) }; return contains(nodes,nodes[root].right,key)
}
rotate_right :: proc "contextless" (nodes: [^]Node, root: int) -> int { p:=nodes[root].left;nodes[root].left=nodes[p].right;nodes[p].right=root;return p }
rotate_left :: proc "contextless" (nodes: [^]Node, root: int) -> int { p:=nodes[root].right;nodes[root].right=nodes[p].left;nodes[p].left=root;return p }
insert_node :: proc "contextless" (nodes: [^]Node, next: ^int, root: int, key: int) -> int {
	if root==0 { id:=next^;next^+=1;nodes[id]=Node{key,priority_for(key),0,0};return id }
	if key==nodes[root].key do return root
	if key<nodes[root].key { child:=insert_node(nodes,next,nodes[root].left,key);nodes[root].left=child;if nodes[child].priority>nodes[root].priority{return rotate_right(nodes,root)} }
	else { child:=insert_node(nodes,next,nodes[root].right,key);nodes[root].right=child;if nodes[child].priority>nodes[root].priority{return rotate_left(nodes,root)} }
	return root
}
merge :: proc "contextless" (nodes: [^]Node, left: int, right: int) -> int {
	if left==0 do return right;if right==0 do return left
	if nodes[left].priority>nodes[right].priority { nodes[left].right=merge(nodes,nodes[left].right,right);return left }
	nodes[right].left=merge(nodes,left,nodes[right].left);return right
}
erase_node :: proc "contextless" (nodes: [^]Node, root: int, key: int) -> int {
	if key<nodes[root].key { nodes[root].left=erase_node(nodes,nodes[root].left,key);return root }
	if key>nodes[root].key { nodes[root].right=erase_node(nodes,nodes[root].right,key);return root }
	return merge(nodes,nodes[root].left,nodes[root].right)
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) { bits:=u64(value);for b:=0;b<8;b+=1 { output[offset+b]=u8(bits>>(8*b)) } }

@(export)
treap_unique_key_set :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil||length<1||input[0]<0||input[0]>MAX_OPS||length!=c.size_t(1+2*input[0]) do return -1
	ops:=int(input[0]);for i:=0;i<ops;i+=1 { op,key:=input[1+2*i],input[2+2*i];if (op!=0&&op!=1)||key< -1_000_000||key>1_000_000 do return -1 }
	var nodes: [MAX_NODES]Node;next:=1;root:=0
	for i:=0;i<ops;i+=1 { op:=int(input[1+2*i]);key:=int(input[2+2*i]);present:=contains(&nodes[0],root,key);if (op==0&&present)||(op==1&&!present) do return -1;if op==0 {root=insert_node(&nodes[0],&next,root,key)}else{root=erase_node(&nodes[0],root,key)} }
	var stack: [MAX_OPS]int;var sorted: [MAX_OPS]i64;top:=0;current:=root;count:=0
	for current!=0||top>0 { for current!=0 {stack[top]=current;top+=1;current=nodes[current].left};top-=1;current=stack[top];sorted[count]=i64(nodes[current].key);count+=1;current=nodes[current].right }
	required:=count*8;if output==nil||capacity<c.size_t(required) do return -2
	for i:=0;i<count;i+=1 {put_i64(output,i*8,sorted[i])};return i64(count)
}
