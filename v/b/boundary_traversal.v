module boundary_traversal
const max_n=100
fn validate(nodes &i64,n usize,node i64,mut seen &bool,mut reached &int) bool {
 if node == -1{return true}if node<0||u64(node)>=u64(n){return false}i:=int(node);unsafe{if seen[i]{return false};seen[i]=true};reached++
 unsafe {v:=nodes[3*i];l:=nodes[3*i+1];r:=nodes[3*i+2];if v< -2147483648||v>2147483647||l< -1||r< -1||(l>=0&&u64(l)>=u64(n))||(r>=0&&u64(r)>=u64(n)){return false};return validate(nodes,n,l,mut seen,mut reached)&&validate(nodes,n,r,mut seen,mut reached)}
}
fn is_leaf(nodes &i64,i int) bool {unsafe{return nodes[3*i+1]==-1&&nodes[3*i+2]==-1}}
fn emit_leaves(nodes &i64,node i64,mut out &i64,mut used &int) {if node == -1{return};i:=int(node);unsafe{if is_leaf(nodes,i){out[used]=nodes[3*i];used++;return};emit_leaves(nodes,nodes[3*i+1],mut out,mut used);emit_leaves(nodes,nodes[3*i+2],mut out,mut used)}}
@[export:'boundary_traversal']
pub fn boundary_traversal(nodes &i64,n usize,root i64,mut out &i64,capacity usize)i64 {
 if n>max_n||capacity<n{return -1}if n==0{return if root == -1{i64(0)}else{i64(-1)}}if unsafe{nodes==nil}||unsafe{out==nil}||root<0||u64(root)>=u64(n){return -1}
 mut seen:=[100]bool{};mut reached:=0;if !validate(nodes,n,root,mut seen[0],mut reached)||reached!=n{return -1}
 mut used:=0;ri:=int(root);unsafe{if !is_leaf(nodes,ri){out[used]=nodes[3*ri];used++}}mut cur:=unsafe{nodes[3*ri+1]};if cur == -1&&unsafe{nodes[3*ri+2]!=-1}{cur=unsafe{nodes[3*ri+2]}}
 for cur!=-1{i:=int(cur);unsafe{if !is_leaf(nodes,i){out[used]=nodes[3*i];used++};cur=if nodes[3*i+1]!=-1{nodes[3*i+1]}else{nodes[3*i+2]}}}
 emit_leaves(nodes,root,mut out,mut used);if unsafe{nodes[3*ri+2]!=-1&&nodes[3*ri+1]==-1}{return i64(used)}
 mut right:=[100]i64{};mut rn:=0;cur=unsafe{nodes[3*ri+2]};for cur!=-1{i:=int(cur);unsafe{if !is_leaf(nodes,i){right[rn]=nodes[3*i];rn++};cur=if nodes[3*i+2]!=-1{nodes[3*i+2]}else{nodes[3*i+1]}}};for rn>0{rn--;unsafe{out[used]=right[rn]};used++};return i64(used)
}
