const MAX_N:usize=100;
fn validate(nodes:&[i64],node:i64,seen:&mut [bool;MAX_N],reached:&mut usize)->bool{
 if node == -1{return true} if node<0||node as usize>=nodes.len()/3{return false} let i=node as usize;if seen[i]{return false}seen[i]=true;*reached+=1;
 let v=nodes[3*i];let l=nodes[3*i+1];let r=nodes[3*i+2];if v<i32::MIN as i64||v>i32::MAX as i64||l< -1||r< -1||l>=0&&l as usize>=nodes.len()/3||r>=0&&r as usize>=nodes.len()/3{return false}
 validate(nodes,l,seen,reached)&&validate(nodes,r,seen,reached)
}
fn leaf(nodes:&[i64],i:usize)->bool{nodes[3*i+1]==-1&&nodes[3*i+2]==-1}
fn emit_leaves(nodes:&[i64],node:i64,out:&mut[i64],used:&mut usize){if node == -1{return}let i=node as usize;if leaf(nodes,i){out[*used]=nodes[3*i];*used+=1;return}emit_leaves(nodes,nodes[3*i+1],out,used);emit_leaves(nodes,nodes[3*i+2],out,used)}
#[no_mangle]
pub unsafe extern "C" fn boundary_traversal(nodes:*const i64,n:usize,root:i64,out:*mut i64,capacity:usize)->i64{
 if n>MAX_N||capacity<n{return -1}if n==0{return if root == -1{0}else{-1}}if nodes.is_null()||out.is_null()||root<0||root as usize>=n{return -1}
 let input=std::slice::from_raw_parts(nodes,3*n);let output=std::slice::from_raw_parts_mut(out,n);let mut seen=[false;MAX_N];let mut reached=0;if !validate(input,root,&mut seen,&mut reached)||reached!=n{return -1}
 let mut used=0;let ri=root as usize;if !leaf(input,ri){output[used]=input[3*ri];used+=1}let mut cur=input[3*ri+1];if cur == -1&&input[3*ri+2]!=-1{cur=input[3*ri+2]}
 while cur!=-1{let i=cur as usize;if !leaf(input,i){output[used]=input[3*i];used+=1}cur=if input[3*i+1]!=-1{input[3*i+1]}else{input[3*i+2]}}
 emit_leaves(input,root,output,&mut used);if input[3*ri+2]!=-1&&input[3*ri+1]==-1{return used as i64}
 let mut right=[0i64;MAX_N];let mut rn=0;cur=input[3*ri+2];while cur!=-1{let i=cur as usize;if !leaf(input,i){right[rn]=input[3*i];rn+=1}cur=if input[3*i+2]!=-1{input[3*i+2]}else{input[3*i+1]}}while rn>0{rn-=1;output[used]=right[rn];used+=1}used as i64
}
