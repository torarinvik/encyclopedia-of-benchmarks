module avl_tree_ruby_unique_key_insert_search

const max_nodes = 64
const max_ops = 128

struct AvlNode { key i64; mut: left int = -1; right int = -1; height int = 0 }
fn node_height(nodes []AvlNode, index int) int { return if index < 0 { 0 } else { nodes[index].height } }
fn update_height(mut nodes []AvlNode, index int) { nodes[index].height = 1 + max(node_height(nodes,nodes[index].left),node_height(nodes,nodes[index].right)) }
fn rotate_right(mut nodes []AvlNode, root int) int { pivot:=nodes[root].left;middle:=nodes[pivot].right;nodes[pivot].right=root;nodes[root].left=middle;update_height(mut nodes,root);update_height(mut nodes,pivot);return pivot }
fn rotate_left(mut nodes []AvlNode, root int) int { pivot:=nodes[root].right;middle:=nodes[pivot].left;nodes[pivot].left=root;nodes[root].right=middle;update_height(mut nodes,root);update_height(mut nodes,pivot);return pivot }
fn insert_node(mut nodes []AvlNode, root int, key i64, mut next int) int {
	if root < 0 { index:=next;next++;nodes[index]=AvlNode{key:key,left:-1,right:-1,height:1};return index }
	if key<nodes[root].key { nodes[root].left=insert_node(mut nodes,nodes[root].left,key,mut next) } else { nodes[root].right=insert_node(mut nodes,nodes[root].right,key,mut next) }
	update_height(mut nodes,root);balance:=node_height(nodes,nodes[root].left)-node_height(nodes,nodes[root].right)
	if balance>1 { if key>nodes[nodes[root].left].key { nodes[root].left=rotate_left(mut nodes,nodes[root].left) };return rotate_right(mut nodes,root) }
	if balance < -1 { if key<nodes[nodes[root].right].key { nodes[root].right=rotate_right(mut nodes,nodes[root].right) };return rotate_left(mut nodes,root) }
	return root
}
fn contains(nodes []AvlNode, root_value int, key i64) bool { mut root:=root_value;for root>=0 { if nodes[root].key==key{return true};root=if key<nodes[root].key{nodes[root].left}else{nodes[root].right} };return false }
fn put_i64(mut output &u8, offset int, value i64) { mut bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits&255)};bits>>=8} }

@[export: 'avl_tree_ruby_unique_key_insert_search']
pub fn avl_tree_ruby_unique_key_insert_search(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<1{return -1}
	unsafe {
		ops64:=input[0];if ops64<0||ops64>max_ops||length!=usize(1+2*ops64){return -1};ops:=int(ops64)
		mut inserted:=[]i64{cap:max_nodes};mut search_count:=0
		for i in 0..ops{op:=input[1+2*i];key:=input[2+2*i];if(op!=0&&op!=1)||key < -1_000_000||key>1_000_000{return -1};if op==0{if inserted.len>=max_nodes||inserted.contains(key){return -1};inserted<<key}else{search_count++}}
		mut nodes:=[]AvlNode{len:max_nodes};for i in 0..max_nodes{nodes[i].left=-1;nodes[i].right=-1}
		mut root:=-1;mut next:=0;mut results:=[]i64{cap:max_ops}
		for i in 0..ops{op:=input[1+2*i];key:=input[2+2*i];if op==0{root=insert_node(mut nodes,root,key,mut next)}else{results<<if contains(nodes,root,key){i64(1)}else{i64(0)}}}
		bytes:=(2+inserted.len+search_count)*8;if output==nil||capacity<usize(bytes){return -2};put_i64(mut output,0,i64(inserted.len))
		mut stack:=[]int{cap:max_nodes};mut current:=root;mut out:=1
		for current>=0||stack.len>0{for current>=0{stack<<current;current=nodes[current].left};current=stack.pop();put_i64(mut output,out*8,nodes[current].key);out++;current=nodes[current].right}
		put_i64(mut output,out*8,i64(search_count));out++;for i in 0..search_count{put_i64(mut output,out*8,results[i]);out++};return i64(bytes)
	}
}
