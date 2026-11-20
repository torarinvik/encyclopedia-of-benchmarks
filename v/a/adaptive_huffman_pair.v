module adaptive_huffman_pair

const alphabet = 16
const max_nodes = 31
const max_symbols = 64
const max_input = 66
const max_packed = 152
const nyt_kind = 0
const leaf_kind = 1
const internal_kind = 2

struct AhNode {
mut:
	parent int
	left int
	right int
	symbol int
	kind int
	weight i64
}
struct AhBits {
mut:
	bytes [max_packed]u8
	count int
}
struct AhTree {
mut:
	nodes [max_nodes]AhNode
	node_count int
	root int
	nyt int
	leaf_of [alphabet]int
	fgk_order [max_nodes]int
	order_count int
	bits AhBits
}
struct AhOrderedNode {
	id int
	depth int
	path int
}

fn put_bit(mut tree &AhTree, value int) {
	if value != 0 { tree.bits.bytes[tree.bits.count/8] |= u8(1 << (7-tree.bits.count%8)) }
	tree.bits.count++
}
fn put_value(mut tree &AhTree, value int, width int) {
	for shift in 0 .. width { put_bit(mut tree,(value>>(width-shift-1))&1) }
}
fn encode_path(mut tree &AhTree, node0 int) {
	mut reverse_path := [max_nodes]int{}
	mut depth := 0
	mut node := node0
	for node != tree.root {
		parent := tree.nodes[node].parent
		reverse_path[depth] = if tree.nodes[parent].right==node { 1 } else { 0 }
		depth++
		node = parent
	}
	for depth > 0 { depth--; put_bit(mut tree,reverse_path[depth]) }
}
fn is_ancestor(tree &AhTree, ancestor int, node int) bool {
	mut parent := tree.nodes[node].parent
	for parent >= 0 { if parent==ancestor { return true }; parent=tree.nodes[parent].parent }
	return false
}
fn replace_child(mut tree &AhTree, parent int, old_child int, new_child int) {
	if tree.nodes[parent].left==old_child { tree.nodes[parent].left=new_child } else if tree.nodes[parent].right==old_child { tree.nodes[parent].right=new_child }
}
fn swap_positions(mut tree &AhTree, a int, b int, update_order bool) {
	if a==b || tree.nodes[a].parent==b || tree.nodes[b].parent==a || is_ancestor(tree,a,b) || is_ancestor(tree,b,a) { return }
	pa,pb := tree.nodes[a].parent,tree.nodes[b].parent
	if pa==pb {
		if pa>=0 { tree.nodes[pa].left,tree.nodes[pa].right=tree.nodes[pa].right,tree.nodes[pa].left }
	} else {
		if pa>=0 { replace_child(mut tree,pa,a,b) }
		if pb>=0 { replace_child(mut tree,pb,b,a) }
		tree.nodes[a].parent=pb; tree.nodes[b].parent=pa
	}
	if tree.root==a { tree.root=b } else if tree.root==b { tree.root=a }
	if update_order {
		mut ra,rb := -1,-1
		for i in 0 .. tree.order_count { if tree.fgk_order[i]==a { ra=i }; if tree.fgk_order[i]==b { rb=i } }
		if ra>=0 && rb>=0 { tree.fgk_order[ra],tree.fgk_order[rb]=tree.fgk_order[rb],tree.fgk_order[ra] }
	}
}
fn initialize(mut tree &AhTree) {
	*tree=AhTree{}
	tree.node_count=1; tree.root=0; tree.nyt=0
	tree.nodes[0]=AhNode{parent:-1,left:-1,right:-1,symbol:-1,kind:nyt_kind,weight:0}
	tree.order_count=1; tree.fgk_order[0]=0
	for i in 0 .. alphabet { tree.leaf_of[i]=-1 }
}
fn add_node(mut tree &AhTree, parent int, kind int, symbol int) int {
	id:=tree.node_count; tree.node_count++
	tree.nodes[id]=AhNode{parent:parent,left:-1,right:-1,symbol:symbol,kind:kind,weight:0}
	return id
}
fn split_nyt(mut tree &AhTree, symbol int, remaining bool, for_fgk bool) int {
	old:=tree.nyt
	if !remaining { tree.nodes[old].kind=leaf_kind; tree.nodes[old].symbol=symbol; tree.leaf_of[symbol]=old; tree.nyt=-1; return old }
	left:=add_node(mut tree,old,nyt_kind,-1); right:=add_node(mut tree,old,leaf_kind,symbol)
	tree.nodes[old].kind=internal_kind; tree.nodes[old].left=left; tree.nodes[old].right=right
	tree.leaf_of[symbol]=right; tree.nyt=left
	if for_fgk {
		mut position:=0; for tree.fgk_order[position]!=old { position++ }
		mut i:=tree.order_count+1; for i>position+2 { tree.fgk_order[i]=tree.fgk_order[i-2]; i-- }
		tree.fgk_order[position]=left; tree.fgk_order[position+1]=right; tree.fgk_order[position+2]=old; tree.order_count+=2
	}
	return right
}
fn fgk_leader(tree &AhTree,node int,leaves_only bool) int {
	weight:=tree.nodes[node].weight; parent:=tree.nodes[node].parent
	mut i:=tree.order_count
	for i>0 {
		i--; candidate:=tree.fgk_order[i]
		if candidate==parent || tree.nodes[candidate].weight!=weight || (leaves_only && tree.nodes[candidate].kind==internal_kind) || is_ancestor(tree,candidate,node) || is_ancestor(tree,node,candidate) { continue }
		return candidate
	}
	return node
}
fn update_fgk(mut tree &AhTree,node0 int) {
	mut node:=node0; parent:=tree.nodes[node].parent
	if tree.nyt>=0 && parent>=0 && tree.nodes[tree.nyt].parent==parent { swap_positions(mut tree,node,fgk_leader(tree,node,true),true); tree.nodes[node].weight++; node=tree.nodes[node].parent }
	for node!=tree.root { swap_positions(mut tree,node,fgk_leader(tree,node,false),true); tree.nodes[node].weight++; node=tree.nodes[node].parent }
	tree.nodes[tree.root].weight++
}
fn implicit_order(mut tree &AhTree,mut order []AhOrderedNode) int {
	for id in 0 .. tree.node_count {
		mut reverse_path:=[max_nodes]int{}; mut depth:=0; mut at:=id; mut path:=0
		for at!=tree.root { parent:=tree.nodes[at].parent; reverse_path[depth]=if tree.nodes[parent].right==at { 1 } else { 0 }; depth++; at=parent }
		mut i:=depth; for i>0 { i--; path=path*2+reverse_path[i] }
		order[id]=AhOrderedNode{id:id,depth:depth,path:path}
	}
	for i in 1 .. tree.node_count { value:=order[i]; mut j:=i; for j>0 && (order[j-1].depth<value.depth || (order[j-1].depth==value.depth && order[j-1].path>value.path)) { order[j]=order[j-1]; j-- }; order[j]=value }
	return tree.node_count
}
fn vitter_leader(mut tree &AhTree,node int,mut order []AhOrderedNode) int {
	count:=implicit_order(mut tree,mut order); mut i:=count
	for i>0 { i--; id:=order[i].id; if tree.nodes[id].weight==tree.nodes[node].weight && tree.nodes[id].kind==tree.nodes[node].kind { return id } }
	return node
}
fn slide_increment(mut tree &AhTree,node int,mut order []AhOrderedNode) int {
	old_parent:=tree.nodes[node].parent
	target_kind:=if tree.nodes[node].kind==leaf_kind { internal_kind } else { leaf_kind }
	target_weight:=tree.nodes[node].weight+if tree.nodes[node].kind==leaf_kind { i64(0) } else { i64(1) }
	count:=implicit_order(mut tree,mut order); mut block:=[]int{cap:max_nodes}
	for i in 0 .. count { id:=order[i].id; if tree.nodes[id].kind==target_kind && tree.nodes[id].weight==target_weight { block<<id } }
	for id in block { swap_positions(mut tree,node,id,false) }
	tree.nodes[node].weight++
	return if tree.nodes[node].kind==leaf_kind { tree.nodes[node].parent } else { old_parent }
}
fn update_vitter(mut tree &AhTree,node0 int,just_split bool) {
	mut order:=[]AhOrderedNode{len:max_nodes}; mut node:=node0; mut leaf_to_increment:=-1
	if just_split { leaf_to_increment=node; node=tree.nodes[node].parent }
	else { swap_positions(mut tree,node,vitter_leader(mut tree,node,mut order),false); parent:=tree.nodes[node].parent; if tree.nyt>=0 && parent>=0 && tree.nodes[tree.nyt].parent==parent { leaf_to_increment=node; node=parent } }
	for node!=tree.root { node=slide_increment(mut tree,node,mut order) }
	if leaf_to_increment>=0 { _=slide_increment(mut tree,leaf_to_increment,mut order) }
	tree.nodes[tree.root].weight++
}
fn run(input &i64,length usize,mut output &u8,capacity usize,vitter bool) i64 {
	unsafe {
		if input==nil || length<1 || length>max_input { return -1 }
		nv:=input[0]; if nv<0 || nv>max_symbols || length!=usize(1+nv) { return -1 }
		n:=int(nv); for i in 0 .. n { if input[i+1]<0 || input[i+1]>=alphabet { return -1 } }
		mut tree:=AhTree{}; initialize(mut tree); mut seen:=0
		for i in 0 .. n {
			symbol:=int(input[i+1]); is_new:=tree.leaf_of[symbol]<0; mut current:=if is_new { tree.nyt } else { tree.leaf_of[symbol] }
			if current<0 { return -1 }
			encode_path(mut tree,current); if is_new { put_value(mut tree,symbol,4) }
			mut just_split:=false
			if is_new { seen++; just_split=seen<alphabet; current=split_nyt(mut tree,symbol,just_split,!vitter) }
			if vitter { update_vitter(mut tree,current,just_split) } else { update_fgk(mut tree,current) }
		}
		packed:=(tree.bits.count+7)/8; required:=8+packed
		if output==nil || capacity<usize(required) { return -2 }
		count:=u64(tree.bits.count); for i in 0 .. 8 { output[i]=u8((count>>(8*i))&255) }
		for i in 0 .. packed { output[8+i]=tree.bits.bytes[i] }
		return i64(required)
	}
}

@[export: 'fgk_adaptive_huffman']
pub fn fgk_adaptive_huffman(input &i64,length usize,mut output &u8,capacity usize) i64 { return run(input,length,mut output,capacity,false) }
@[export: 'vitter_adaptive_huffman']
pub fn vitter_adaptive_huffman(input &i64,length usize,mut output &u8,capacity usize) i64 { return run(input,length,mut output,capacity,true) }
