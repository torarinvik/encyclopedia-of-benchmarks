#include <cstddef>
#include <cstdint>

constexpr int MAX_OPS=32, POOL_CAP=8192, OUT_I64_CAP=5000;
struct Node { int value, left, right, height; };
static int height(const Node* p,int id){return id==0?-1:p[id].height;}
static int make_node(Node* p,int* next,int v,int l,int r){int id=(*next)++;p[id]={v,l,r,1+(height(p,l)>height(p,r)?height(p,l):height(p,r))};return id;}
static int balance(const Node*p,int id){return height(p,p[id].right)-height(p,p[id].left);}
static int rotate_right(Node*p,int*next,int root){int left=p[root].left;int moved=make_node(p,next,p[root].value,p[left].right,p[root].right);return make_node(p,next,p[left].value,p[left].left,moved);}
static int rotate_left(Node*p,int*next,int root){int right=p[root].right;int moved=make_node(p,next,p[root].value,p[root].left,p[right].left);return make_node(p,next,p[right].value,moved,p[right].right);}
static int rebalance(Node*p,int*next,int root){int bf=balance(p,root);if(bf>1){if(balance(p,p[root].right)<0){int rotated=rotate_right(p,next,p[root].right);root=make_node(p,next,p[root].value,p[root].left,rotated);}return rotate_left(p,next,root);}if(bf< -1){if(balance(p,p[root].left)>0){int rotated=rotate_left(p,next,p[root].left);root=make_node(p,next,p[root].value,rotated,p[root].right);}return rotate_right(p,next,root);}return root;}
static int insert_node(Node*p,int*next,int root,int value){if(!root)return make_node(p,next,value,0,0);if(value==p[root].value)return root;if(value<p[root].value){int l=insert_node(p,next,p[root].left,value);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}int r=insert_node(p,next,p[root].right,value);return rebalance(p,next,make_node(p,next,p[root].value,p[root].left,r));}
static int delete_min(Node*p,int*next,int root,int*minimum){if(!p[root].left){*minimum=p[root].value;return p[root].right;}int l=delete_min(p,next,p[root].left,minimum);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}
static int delete_node(Node*p,int*next,int root,int value){if(!root)return 0;if(value<p[root].value){int l=delete_node(p,next,p[root].left,value);return rebalance(p,next,make_node(p,next,p[root].value,l,p[root].right));}if(value>p[root].value){int r=delete_node(p,next,p[root].right,value);return rebalance(p,next,make_node(p,next,p[root].value,p[root].left,r));}if(!p[root].left)return p[root].right;if(!p[root].right)return p[root].left;int successor=0;int r=delete_min(p,next,p[root].right,&successor);return rebalance(p,next,make_node(p,next,successor,p[root].left,r));}
static void put_i64(std::int64_t v,std::uint8_t*out,std::size_t off){std::uint64_t b=static_cast<std::uint64_t>(v);for(std::size_t i=0;i<8;++i)out[off+i]=static_cast<std::uint8_t>(b>>(8*i));}

extern "C" std::int64_t avltree_persistent_insert_delete(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept{
 if(!input||length<1||input[0]<0||input[0]>MAX_OPS||length!=1+3*static_cast<std::size_t>(input[0]))return -1;
 const auto ops=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<ops;++i){auto parent=input[1+3*i],op=input[2+3*i],value=input[3+3*i];if(parent<0||parent>static_cast<std::int64_t>(i)||(op!=0&&op!=1)||value< -1000||value>1000)return -1;}
 Node pool[POOL_CAP]{};int next=1;int roots[MAX_OPS+1]{};
 for(std::size_t i=0;i<ops;++i){int base=roots[input[1+3*i]];roots[i+1]=input[2+3*i]==0?insert_node(pool,&next,base,static_cast<int>(input[3+3*i])):delete_node(pool,&next,base,static_cast<int>(input[3+3*i]));if(next>=POOL_CAP-64)return -1;}
 std::int64_t packed[OUT_I64_CAP];std::size_t used=0;packed[used++]=static_cast<std::int64_t>(ops+1);
 for(std::size_t ver=0;ver<=ops;++ver){int root=roots[ver],queue[MAX_OPS+1],local[POOL_CAP],left_id[MAX_OPS+1],right_id[MAX_OPS+1];for(int i=0;i<POOL_CAP;++i)local[i]=-1;std::size_t tail=0;if(root){queue[tail]=root;local[root]=0;tail=1;}for(std::size_t head=0;head<tail;++head){left_id[head]=right_id[head]=-1;int child[2]={pool[queue[head]].left,pool[queue[head]].right};for(int side=0;side<2;++side)if(child[side]){if(local[child[side]]<0){local[child[side]]=static_cast<int>(tail);queue[tail++]=child[side];}if(side==0)left_id[head]=local[child[side]];else right_id[head]=local[child[side]];}}
  packed[used++]=static_cast<std::int64_t>(tail);packed[used++]=height(pool,root);for(std::size_t i=0;i<tail;++i){packed[used++]=pool[queue[i]].value;packed[used++]=pool[queue[i]].height;packed[used++]=left_id[i];packed[used++]=right_id[i];}}
 const std::size_t required=used*8;if(!output||capacity<required)return -2;for(std::size_t i=0;i<used;++i)put_i64(packed[i],output,8*i);return static_cast<std::int64_t>(required);
}
