module boundary_traversal;
const usz MAX_N=100;
fn bool validate(long* n,usz count,long node,bool* seen,usz* reached){if(node==-1)return true;if(node<0||(usz)node>=count)return false;usz i=(usz)node;if(seen[i])return false;seen[i]=true;*reached+=1;long v=n[3*i],l=n[3*i+1],r=n[3*i+2];if(v< -2147483648L||v>2147483647L||l< -1||r< -1||(l>=0&&(usz)l>=count)||(r>=0&&(usz)r>=count))return false;return validate(n,count,l,seen,reached)&&validate(n,count,r,seen,reached);}
fn bool leaf(long* n,usz i){return n[3*i+1]==-1&&n[3*i+2]==-1;}
fn void emit_leaves(long* n,long node,long* out,usz* used){if(node==-1)return;usz i=(usz)node;if(leaf(n,i)){out[*used]=n[3*i];*used+=1;return;}emit_leaves(n,n[3*i+1],out,used);emit_leaves(n,n[3*i+2],out,used);}
fn long boundary_traversal(long* nodes,usz count,long root,long* output,usz capacity) @export("boundary_traversal") {
 if(count>MAX_N||capacity<count)return -1;if(count==0)return root==-1?0:-1;if(nodes==null||output==null||root<0||(usz)root>=count)return -1;
 bool[MAX_N] seen=zeroed;usz reached=0;if(!validate(nodes,count,root,&seen[0],&reached)||reached!=count)return -1;
 usz used=0,ri=(usz)root;if(!leaf(nodes,ri)){output[used]=nodes[3*ri];used++;}
 long cur=nodes[3*ri+1];if(cur==-1&&nodes[3*ri+2]!=-1)cur=nodes[3*ri+2];while(cur!=-1){usz i=(usz)cur;if(!leaf(nodes,i)){output[used]=nodes[3*i];used++;}cur=nodes[3*i+1]!=-1?nodes[3*i+1]:nodes[3*i+2];}
 emit_leaves(nodes,root,output,&used);if(nodes[3*ri+2]!=-1&&nodes[3*ri+1]==-1)return (long)used;
 long[MAX_N] right;usz rn=0;cur=nodes[3*ri+2];while(cur!=-1){usz i=(usz)cur;if(!leaf(nodes,i)){right[rn]=nodes[3*i];rn++;}cur=nodes[3*i+2]!=-1?nodes[3*i+2]:nodes[3*i+1];}while(rn>0){rn--;output[used]=right[rn];used++;}return (long)used;
}
