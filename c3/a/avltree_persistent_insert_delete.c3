module avltree_persistent_insert_delete;

const int MAX_OPS=32; const int POOL_CAP=8192; const int OUT_CAP=5000;
struct Node { int value; int left; int right; int height; }
fn int node_height(Node* p,int id){return id==0?-1:p[id].height;}
fn int make_node(Node* p,int* next,int value,int left,int right){int id=*next;*next+=1;p[id]={value,left,right,1+(node_height(p,left)>node_height(p,right)?node_height(p,left):node_height(p,right))};return id;}
fn int balance(Node* p,int id){return node_height(p,p[id].right)-node_height(p,p[id].left);}
fn int rotate_right(Node* p,int* next,int root){int left=p[root].left;int moved=make_node(p,next,p[root].value,p[left].right,p[root].right);return make_node(p,next,p[left].value,p[left].left,moved);}
fn int rotate_left(Node* p,int* next,int root){int right=p[root].right;int moved=make_node(p,next,p[root].value,p[root].left,p[right].left);return make_node(p,next,p[right].value,moved,p[right].right);}
fn int rebalance(Node* p,int* next,int root){int bf=balance(p,root);if(bf>1){if(balance(p,p[root].right)<0){int r=rotate_right(p,next,p[root].right);root=make_node(p,next,p[root].value,p[root].left,r);}return rotate_left(p,next,root);}if(bf< -1){if(balance(p,p[root].left)>0){int l=rotate_left(p,next,p[root].left);root=make_node(p,next,p[root].value,l,p[root].right);}return rotate_right(p,next,root);}return root;}
fn int insert_node(Node* p,int* next,int root,int value){if(root==0)return make_node(p,next,value,0,0);if(value==p[root].value)return root;if(value<p[root].value){int l=insert_node(p,next,p[root].left,value);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}int r=insert_node(p,next,p[root].right,value);return rebalance(p,next,make_node(p,next,p[root].value,p[root].left,r));}
fn int delete_min(Node* p,int* next,int root,int* minimum){if(p[root].left==0){*minimum=p[root].value;return p[root].right;}int l=delete_min(p,next,p[root].left,minimum);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}
fn int delete_node(Node* p,int* next,int root,int value){if(root==0)return 0;if(value<p[root].value){int l=delete_node(p,next,p[root].left,value);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}if(value>p[root].value){int r=delete_node(p,next,p[root].right,value);return rebalance(p,next,make_node(p,next,p[root].value,p[root].left,r));}if(p[root].left==0)return p[root].right;if(p[root].right==0)return p[root].left;int successor=0;int r=delete_min(p,next,p[root].right,&successor);return rebalance(p,next,make_node(p,next,successor,p[root].left,r));}
fn void put_i64(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b));}

fn long avltree_persistent_insert_delete(long* input,usz length,char* output,usz capacity) @export("avltree_persistent_insert_delete"){
 if(input==null||length<1||input[0]<0||input[0]>MAX_OPS||length!=1+3*(usz)input[0])return -1;
 usz ops=(usz)input[0];for(usz i=0;i<ops;i++){long parent=input[1+3*i],op=input[2+3*i],value=input[3+3*i];if(parent<0||parent>(long)i||(op!=0&&op!=1)||value< -1000||value>1000)return -1;}
 Node[POOL_CAP] pool;int next=1;int[MAX_OPS+1] roots;for(int i=0;i<=MAX_OPS;i++)roots[i]=0;
 for(usz i=0;i<ops;i++){int root=roots[input[1+3*i]];roots[i+1]=input[2+3*i]==0?insert_node(&pool[0],&next,root,(int)input[3+3*i]):delete_node(&pool[0],&next,root,(int)input[3+3*i]);if(next>=POOL_CAP-64)return -1;}
 long[OUT_CAP] packed;usz used=0;packed[used++]=(long)ops+1;
 for(usz ver=0;ver<=ops;ver++){
  int root=roots[ver];int[MAX_OPS+1] queue;int[POOL_CAP] local;int[MAX_OPS+1] left_id,right_id;for(int i=0;i<POOL_CAP;i++)local[i]=-1;
  usz tail=0;if(root!=0){queue[0]=root;local[root]=0;tail=1;}
  for(usz head=0;head<tail;head++){left_id[head]=-1;right_id[head]=-1;int[2] children={pool[queue[head]].left,pool[queue[head]].right};for(int side=0;side<2;side++)if(children[side]!=0){int child=children[side];if(local[child]<0){local[child]=(int)tail;queue[tail++]=child;}if(side==0)left_id[head]=local[child];else right_id[head]=local[child];}}
  packed[used++]=(long)tail;packed[used++]=(long)node_height(&pool[0],root);
  for(usz i=0;i<tail;i++){Node n=pool[queue[i]];packed[used++]=n.value;packed[used++]=n.height;packed[used++]=left_id[i];packed[used++]=right_id[i];}
 }
 usz required=used*8;if(output==null||capacity<required)return -2;for(usz i=0;i<used;i++)put_i64(output,8*i,packed[i]);return (long)required;
}
