#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_NODES=64, MAX_OPS=128;
struct Node { std::int64_t key; int left=-1,right=-1,height=1; };
int height(const Node *nodes,int i){return i<0?0:nodes[i].height;}
void update(Node *nodes,int i){const int a=height(nodes,nodes[i].left),b=height(nodes,nodes[i].right);nodes[i].height=1+(a>b?a:b);}
int rotate_right(Node *nodes,int root){const int pivot=nodes[root].left,middle=nodes[pivot].right;nodes[pivot].right=root;nodes[root].left=middle;update(nodes,root);update(nodes,pivot);return pivot;}
int rotate_left(Node *nodes,int root){const int pivot=nodes[root].right,middle=nodes[pivot].left;nodes[pivot].left=root;nodes[root].right=middle;update(nodes,root);update(nodes,pivot);return pivot;}
int insert(Node *nodes,int root,std::int64_t key,int &next){if(root<0){const int i=next++;nodes[i]=Node{key,-1,-1,1};return i;}if(key<nodes[root].key)nodes[root].left=insert(nodes,nodes[root].left,key,next);else nodes[root].right=insert(nodes,nodes[root].right,key,next);update(nodes,root);const int bf=height(nodes,nodes[root].left)-height(nodes,nodes[root].right);if(bf>1){if(key>nodes[nodes[root].left].key)nodes[root].left=rotate_left(nodes,nodes[root].left);return rotate_right(nodes,root);}if(bf < -1){if(key<nodes[nodes[root].right].key)nodes[root].right=rotate_right(nodes,nodes[root].right);return rotate_left(nodes,root);}return root;}
bool contains(const Node *nodes,int root,std::int64_t key){while(root>=0){if(nodes[root].key==key)return true;root=key<nodes[root].key?nodes[root].left:nodes[root].right;}return false;}
void put_i64(std::uint8_t *out,std::size_t off,std::int64_t v){const auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[off+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t avl_tree_ruby_unique_key_insert_search(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(!input||length<1)return -1;const auto op_count=input[0];if(op_count<0||op_count>MAX_OPS||length!=static_cast<std::size_t>(1+2*op_count))return -1;
    std::int64_t inserted[MAX_NODES];std::size_t ni=0,ns=0;std::uint8_t results[MAX_OPS];
    for(std::size_t i=0;i<static_cast<std::size_t>(op_count);++i){const auto op=input[1+2*i],key=input[2+2*i];if((op!=0&&op!=1)||key < -1000000||key>1000000)return -1;if(op==0){if(ni>=MAX_NODES)return -1;for(std::size_t j=0;j<ni;++j)if(inserted[j]==key)return -1;inserted[ni++]=key;}}
    Node nodes[MAX_NODES]{};int root=-1,next=0;std::size_t q=0;
    for(std::size_t i=0;i<static_cast<std::size_t>(op_count);++i){const auto op=input[1+2*i],key=input[2+2*i];if(op==0)root=insert(nodes,root,key,next);else results[q++]=contains(nodes,root,key)?1:0;}
    for(std::size_t i=0;i<static_cast<std::size_t>(op_count);++i)if(input[1+2*i]==1)++ns;
    const std::size_t bytes=(2+ni+ns)*8;if(!output||capacity<bytes)return -2;put_i64(output,0,static_cast<std::int64_t>(ni));int stack[MAX_NODES],top=0,current=root;std::size_t out=1;
    while(current>=0||top){while(current>=0){stack[top++]=current;current=nodes[current].left;}current=stack[--top];put_i64(output,out++*8,nodes[current].key);current=nodes[current].right;}
    put_i64(output,out++*8,static_cast<std::int64_t>(ns));for(std::size_t i=0;i<ns;++i)put_i64(output,out++*8,results[i]);return static_cast<std::int64_t>(bytes);
}
