package adaptive_huffman_pair

import "core:c"

ALPHABET :: 16
MAX_NODES :: 31
MAX_INPUT :: 66
MAX_PACKED :: 152
NYT :: 0
LEAF :: 1
INTERNAL :: 2

AhNode :: struct { parent, left, right, symbol, kind: int, weight: i64 }
AhOrdered :: struct { id, depth, path: int }
AhTree :: struct {
	nodes: [MAX_NODES]AhNode,
	count, root, nyt: int,
	leaf: [ALPHABET]int,
	order: [MAX_NODES]int,
	order_count: int,
	bits: [MAX_PACKED]u8,
	bit_count: int,
}

put_bit :: proc(tree: ^AhTree, value: int) {
	if value != 0 do tree.bits[tree.bit_count/8] |= u8(1 << (7-tree.bit_count%8))
	tree.bit_count += 1
}
put_value :: proc(tree: ^AhTree, value, width: int) { for shift := width-1; shift >= 0; shift -= 1 { put_bit(tree,(value>>shift)&1) } }
encode_path :: proc(tree: ^AhTree, start: int) {
	reverse: [MAX_NODES]int
	depth, node := 0, start
	for node != tree.root { parent:=tree.nodes[node].parent; reverse[depth]=if tree.nodes[parent].right==node then 1 else 0; depth+=1; node=parent }
	for depth>0 { depth-=1; put_bit(tree,reverse[depth]) }
}
is_ancestor :: proc(tree: ^AhTree, ancestor, node: int) -> bool {
	parent:=tree.nodes[node].parent
	for parent>=0 { if parent==ancestor do return true; parent=tree.nodes[parent].parent }
	return false
}
replace_child :: proc(tree: ^AhTree,parent,old,new: int) { if tree.nodes[parent].left==old {tree.nodes[parent].left=new} else if tree.nodes[parent].right==old {tree.nodes[parent].right=new} }
swap_positions :: proc(tree: ^AhTree,a,b: int,update_order: bool) {
	if a==b || tree.nodes[a].parent==b || tree.nodes[b].parent==a || is_ancestor(tree,a,b) || is_ancestor(tree,b,a) do return
	pa,pb:=tree.nodes[a].parent,tree.nodes[b].parent
	if pa==pb {if pa>=0 {tree.nodes[pa].left,tree.nodes[pa].right=tree.nodes[pa].right,tree.nodes[pa].left}}
	else {if pa>=0 {replace_child(tree,pa,a,b)};if pb>=0 {replace_child(tree,pb,b,a)};tree.nodes[a].parent=pb;tree.nodes[b].parent=pa}
	if tree.root==a {tree.root=b} else if tree.root==b {tree.root=a}
	if update_order {ra,rb:=-1,-1;for i:=0;i<tree.order_count;i+=1 {if tree.order[i]==a {ra=i};if tree.order[i]==b {rb=i}};if ra>=0&&rb>=0 {tree.order[ra],tree.order[rb]=b,a}}
}
add_node :: proc(tree: ^AhTree,parent,kind,symbol: int) -> int {id:=tree.count;tree.count+=1;tree.nodes[id]=AhNode{parent,-1,-1,symbol,kind,0};return id}
split_nyt :: proc(tree: ^AhTree,symbol: int,remaining,fgk: bool) -> int {
	old:=tree.nyt
	if !remaining {tree.nodes[old].kind=LEAF;tree.nodes[old].symbol=symbol;tree.leaf[symbol]=old;tree.nyt=-1;return old}
	left:=add_node(tree,old,NYT,-1);right:=add_node(tree,old,LEAF,symbol);tree.nodes[old].kind=INTERNAL;tree.nodes[old].left=left;tree.nodes[old].right=right;tree.leaf[symbol]=right;tree.nyt=left
	if fgk {position:=0;for tree.order[position]!=old {position+=1};for i:=tree.order_count+1;i>position+2;i-=1 {tree.order[i]=tree.order[i-2]};tree.order[position]=left;tree.order[position+1]=right;tree.order[position+2]=old;tree.order_count+=2}
	return right
}
fgk_leader :: proc(tree: ^AhTree,node: int,leaves_only: bool) -> int {
	parent:=tree.nodes[node].parent
	for i:=tree.order_count-1;i>=0;i-=1 {candidate:=tree.order[i];if candidate==parent || tree.nodes[candidate].weight!=tree.nodes[node].weight || (leaves_only&&tree.nodes[candidate].kind==INTERNAL) || is_ancestor(tree,candidate,node) || is_ancestor(tree,node,candidate) {continue};return candidate}
	return node
}
update_fgk :: proc(tree: ^AhTree,start: int) {
	node:=start;parent:=tree.nodes[node].parent
	if tree.nyt>=0&&parent>=0&&tree.nodes[tree.nyt].parent==parent {swap_positions(tree,node,fgk_leader(tree,node,true),true);tree.nodes[node].weight+=1;node=tree.nodes[node].parent}
	for node!=tree.root {swap_positions(tree,node,fgk_leader(tree,node,false),true);tree.nodes[node].weight+=1;node=tree.nodes[node].parent}
	tree.nodes[tree.root].weight+=1
}
implicit_order :: proc(tree: ^AhTree,order: ^[MAX_NODES]AhOrdered) -> int {
	for id:=0;id<tree.count;id+=1 {reverse:[MAX_NODES]int;depth,at,path:=0,id,0;for at!=tree.root {parent:=tree.nodes[at].parent;reverse[depth]=if tree.nodes[parent].right==at then 1 else 0;depth+=1;at=parent};for i:=depth-1;i>=0;i-=1 {path=path*2+reverse[i]};order[id]=AhOrdered{id,depth,path}}
	for i:=1;i<tree.count;i+=1 {value:=order[i];j:=i;for j>0&&(order[j-1].depth<value.depth||(order[j-1].depth==value.depth&&order[j-1].path>value.path)){order[j]=order[j-1];j-=1};order[j]=value}
	return tree.count
}
vitter_leader :: proc(tree: ^AhTree,node: int,order: ^[MAX_NODES]AhOrdered) -> int {count:=implicit_order(tree,order);for i:=count-1;i>=0;i-=1 {id:=order[i].id;if tree.nodes[id].weight==tree.nodes[node].weight&&tree.nodes[id].kind==tree.nodes[node].kind {return id}};return node}
slide_increment :: proc(tree: ^AhTree,node: int,order: ^[MAX_NODES]AhOrdered) -> int {
	old_parent:=tree.nodes[node].parent;target_kind:=if tree.nodes[node].kind==LEAF then INTERNAL else LEAF;target_weight:=tree.nodes[node].weight+if tree.nodes[node].kind==LEAF then 0 else 1
	count:=implicit_order(tree,order);block:[MAX_NODES]int;used:=0
	for i:=0;i<count;i+=1 {id:=order[i].id;if tree.nodes[id].kind==target_kind&&tree.nodes[id].weight==target_weight {block[used]=id;used+=1}}
	for i:=0;i<used;i+=1 {if block[i]!=node {swap_positions(tree,node,block[i],false)}}
	tree.nodes[node].weight+=1
	if tree.nodes[node].kind==LEAF {return tree.nodes[node].parent};return old_parent
}
update_vitter :: proc(tree: ^AhTree,start: int,just_split: bool) {
	order:[MAX_NODES]AhOrdered;node:=start;leaf_to_increment:=-1
	if just_split {leaf_to_increment=node;node=tree.nodes[node].parent}
	else {swap_positions(tree,node,vitter_leader(tree,node,&order),false);parent:=tree.nodes[node].parent;if tree.nyt>=0&&parent>=0&&tree.nodes[tree.nyt].parent==parent {leaf_to_increment=node;node=parent}}
	for node!=tree.root {node=slide_increment(tree,node,&order)}
	if leaf_to_increment>=0 {_=slide_increment(tree,leaf_to_increment,&order)}
	tree.nodes[tree.root].weight+=1
}
run :: proc(input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t,use_vitter: bool) -> i64 {
	if input==nil||length<1||length>c.size_t(MAX_INPUT) do return -1
	nv:=input[0];if nv<0||nv>64||length!=c.size_t(1+nv) do return -1
	for i:=0;i<int(nv);i+=1 {if input[1+i]<0||input[1+i]>=ALPHABET do return -1}
	tree:=AhTree{};tree.count=1;tree.root=0;tree.nyt=0;tree.nodes[0]=AhNode{-1,-1,-1,-1,NYT,0};tree.order_count=1;tree.order[0]=0;for i:=0;i<ALPHABET;i+=1 {tree.leaf[i]=-1}
	seen:=0
	for i:=0;i<int(nv);i+=1 {symbol:=int(input[1+i]);is_new:=tree.leaf[symbol]<0;current:=if is_new then tree.nyt else tree.leaf[symbol];encode_path(&tree,current);if is_new {put_value(&tree,symbol,4);seen+=1;just_split:=seen<ALPHABET;current=split_nyt(&tree,symbol,just_split,!use_vitter);if use_vitter {update_vitter(&tree,current,just_split)} else {update_fgk(&tree,current)}} else {if use_vitter {update_vitter(&tree,current,false)} else {update_fgk(&tree,current)}}}
	packed:=(tree.bit_count+7)/8;required:=8+packed;if output==nil||capacity<c.size_t(required) do return -2
	count:=u64(tree.bit_count);for i:=0;i<8;i+=1 {output[i]=u8((count>>(8*i))&255)};for i:=0;i<packed;i+=1 {output[8+i]=tree.bits[i]};return i64(required)
}
@(export)
fgk_adaptive_huffman :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t) -> i64 {return run(input,length,output,capacity,false)}
@(export)
vitter_adaptive_huffman :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t) -> i64 {return run(input,length,output,capacity,true)}
