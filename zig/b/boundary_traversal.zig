const MAX_N:usize=100;
fn validate(nodes:[*]const i64,n:usize,node:i64,seen:[*]bool,reached:*usize)bool{
 if(node == -1)return true;if(node<0 or @as(u64,@intCast(node))>=n)return false;const i:usize=@intCast(node);if(seen[i])return false;seen[i]=true;reached.*+=1;
 const v=nodes[3*i];const l=nodes[3*i+1];const r=nodes[3*i+2];if(v< -2147483648 or v>2147483647 or l< -1 or r< -1 or (l>=0 and @as(u64,@intCast(l))>=n) or (r>=0 and @as(u64,@intCast(r))>=n))return false;return validate(nodes,n,l,seen,reached) and validate(nodes,n,r,seen,reached);
}
fn isLeaf(nodes:[*]const i64,i:usize)bool{return nodes[3*i+1]==-1 and nodes[3*i+2]==-1;}
fn emitLeaves(nodes:[*]const i64,node:i64,out:[*]i64,used:*usize)void{if(node == -1)return;const i:usize=@intCast(node);if(isLeaf(nodes,i)){out[used.*]=nodes[3*i];used.*+=1;return;}emitLeaves(nodes,nodes[3*i+1],out,used);emitLeaves(nodes,nodes[3*i+2],out,used);}
pub export fn boundary_traversal(nodes:[*c]const i64,n:usize,root:i64,out:[*c]i64,capacity:usize)i64{
 if(n>MAX_N or capacity<n)return -1;if(n==0)return if(root == -1)0 else -1;if(nodes==null or out==null or root<0 or @as(u64,@intCast(root))>=n)return -1;
 var seen:[MAX_N]bool=@splat(false);var reached:usize=0;if(!validate(nodes,n,root,&seen,&reached) or reached!=n)return -1;
 var used:usize=0;const ri:usize=@intCast(root);if(!isLeaf(nodes,ri)){out[used]=nodes[3*ri];used+=1;}var cur=nodes[3*ri+1];if(cur == -1 and nodes[3*ri+2]!=-1)cur=nodes[3*ri+2];
 while(cur!=-1){const i:usize=@intCast(cur);if(!isLeaf(nodes,i)){out[used]=nodes[3*i];used+=1;}cur=if(nodes[3*i+1]!=-1)nodes[3*i+1] else nodes[3*i+2];}
 emitLeaves(nodes,root,out,&used);if(nodes[3*ri+2]!=-1 and nodes[3*ri+1]==-1)return @intCast(used);
 var right:[MAX_N]i64=@splat(0);var rn:usize=0;cur=nodes[3*ri+2];while(cur!=-1){const i:usize=@intCast(cur);if(!isLeaf(nodes,i)){right[rn]=nodes[3*i];rn+=1;}cur=if(nodes[3*i+2]!=-1)nodes[3*i+2] else nodes[3*i+1];}while(rn>0){rn-=1;out[used]=right[rn];used+=1;}return @intCast(used);
}
