package avl_tree_ruby_unique_key_insert_search

import "core:c"

MAX_NODES :: 64
MAX_OPS :: 128
Node :: struct { key: i64, left, right, height: i32 }
height :: proc(nodes: [^]Node, index: i32) -> i32 { if index < 0 { return 0 }; return nodes[index].height }
update :: proc(nodes: [^]Node, index: i32) { a:=height(nodes,nodes[index].left);b:=height(nodes,nodes[index].right);nodes[index].height=1+max(a,b) }
rotate_right :: proc(nodes: [^]Node, root: i32) -> i32 { pivot:=nodes[root].left;middle:=nodes[pivot].right;nodes[pivot].right=root;nodes[root].left=middle;update(nodes,root);update(nodes,pivot);return pivot }
rotate_left :: proc(nodes: [^]Node, root: i32) -> i32 { pivot:=nodes[root].right;middle:=nodes[pivot].left;nodes[pivot].left=root;nodes[root].right=middle;update(nodes,root);update(nodes,pivot);return pivot }
insert_node :: proc(nodes: [^]Node, root: i32, key: i64, next: ^i32) -> i32 {
	if root<0 { i:=next^;next^+=1;nodes[i]=Node{key=key,left=-1,right=-1,height=1};return i }
	if key<nodes[root].key { nodes[root].left=insert_node(nodes,nodes[root].left,key,next) } else { nodes[root].right=insert_node(nodes,nodes[root].right,key,next) }
	update(nodes,root);bf:=height(nodes,nodes[root].left)-height(nodes,nodes[root].right)
	if bf>1 { if key>nodes[nodes[root].left].key { nodes[root].left=rotate_left(nodes,nodes[root].left) }; return rotate_right(nodes,root) }
	if bf < -1 { if key<nodes[nodes[root].right].key { nodes[root].right=rotate_right(nodes,nodes[root].right) }; return rotate_left(nodes,root) }
	return root
}
contains :: proc(nodes: [^]Node, root_value: i32, key: i64) -> bool { root:=root_value;for root>=0 { if nodes[root].key==key{return true};if key<nodes[root].key{root=nodes[root].left}else{root=nodes[root].right} };return false }
put_i64 :: proc(out: [^]u8, offset: int, value: i64) { bits:=transmute(u64)value;for b:=0;b<8;b+=1{out[offset+b]=u8(bits>>u64(b*8))} }

@(export)
avl_tree_ruby_unique_key_insert_search :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t)->i64 {
	if input==nil||length<1 do return -1;ops64:=input[0];if ops64<0||ops64>MAX_OPS||length!=c.size_t(1+2*ops64) do return -1;n:=int(ops64)
	var inserted:[MAX_NODES]i64;ni,ns:=0,0
	for i:=0;i<n;i+=1{op,key:=input[1+2*i],input[2+2*i];if(op!=0&&op!=1)||key < -1_000_000||key>1_000_000 do return -1;if op==0{if ni>=MAX_NODES do return -1;for j:=0;j<ni;j+=1{if inserted[j]==key do return -1};inserted[ni]=key;ni+=1}else{ns+=1}}
	var nodes:[MAX_NODES]Node;for i:=0;i<MAX_NODES;i+=1{nodes[i].left=-1;nodes[i].right=-1}
	root:i32=-1;next:i32=0;var results:[MAX_OPS]i64;q:=0
	for i:=0;i<n;i+=1{op,key:=input[1+2*i],input[2+2*i];if op==0{root=insert_node(&nodes,root,key,&next)}else{results[q]=0;if contains(&nodes,root,key){results[q]=1};q+=1}}
	bytes:=(2+ni+ns)*8;if output==nil||capacity<c.size_t(bytes) do return -2;put_i64(output,0,i64(ni));var stack:[MAX_NODES]i32;top:=0;current:=root;out:=1
	for current>=0||top>0{for current>=0{stack[top]=current;top+=1;current=nodes[current].left};top-=1;current=stack[top];put_i64(output,out*8,nodes[current].key);out+=1;current=nodes[current].right}
	put_i64(output,out*8,i64(ns));out+=1;for i:=0;i<ns;i+=1{put_i64(output,out*8,results[i]);out+=1};return i64(bytes)
}
