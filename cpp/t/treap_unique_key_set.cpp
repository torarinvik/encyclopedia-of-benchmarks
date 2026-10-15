#include <cstddef>
#include <cstdint>

constexpr int MAX_OPS = 128;
constexpr int MAX_NODES = MAX_OPS + 1;
struct Node { std::int32_t key; int left, right; std::int64_t priority; };
static std::int64_t priority_for(std::int32_t key) { return ((static_cast<std::int64_t>(key) + 1000000) * 1103515245 + 12345) % 2147483648LL; }
static bool contains(const Node* n, int root, std::int32_t key) { if (!root) return false; if (key == n[root].key) return true; return contains(n, key < n[root].key ? n[root].left : n[root].right, key); }
static int rotate_right(Node* n, int root) { int p=n[root].left; n[root].left=n[p].right; n[p].right=root; return p; }
static int rotate_left(Node* n, int root) { int p=n[root].right; n[root].right=n[p].left; n[p].left=root; return p; }
static int insert_node(Node* n, int* next, int root, std::int32_t key) {
    if (!root) { int id=(*next)++; n[id]=Node{key,0,0,priority_for(key)}; return id; }
    if (key==n[root].key) return root;
    if (key<n[root].key) { n[root].left=insert_node(n,next,n[root].left,key); if(n[n[root].left].priority>n[root].priority) root=rotate_right(n,root); }
    else { n[root].right=insert_node(n,next,n[root].right,key); if(n[n[root].right].priority>n[root].priority) root=rotate_left(n,root); }
    return root;
}
static int merge(Node* n,int a,int b) { if(!a)return b; if(!b)return a; if(n[a].priority>n[b].priority){n[a].right=merge(n,n[a].right,b);return a;} n[b].left=merge(n,a,n[b].left);return b; }
static int erase_node(Node* n,int root,std::int32_t key) { if(key<n[root].key)n[root].left=erase_node(n,n[root].left,key);else if(key>n[root].key)n[root].right=erase_node(n,n[root].right,key);else return merge(n,n[root].left,n[root].right);return root; }
static void put_i64(std::uint8_t* out,std::size_t off,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[off+b]=static_cast<std::uint8_t>(bits>>(8*b));}
extern "C" std::int64_t treap_unique_key_set(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if(!input||length<1||input[0]<0||input[0]>MAX_OPS||length!=1+2*static_cast<std::size_t>(input[0]))return -1;
    const auto ops=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<ops;++i){auto op=input[1+2*i],key=input[2+2*i];if((op!=0&&op!=1)||key< -1000000||key>1000000)return -1;}
    Node nodes[MAX_NODES]{};int next=1,root=0;
    for(std::size_t i=0;i<ops;++i){int op=static_cast<int>(input[1+2*i]);auto key=static_cast<std::int32_t>(input[2+2*i]);bool present=contains(nodes,root,key);if((op==0&&present)||(op==1&&!present))return -1;root=op==0?insert_node(nodes,&next,root,key):erase_node(nodes,root,key);}
    int stack[MAX_OPS];int top=0,current=root;std::int64_t sorted[MAX_OPS];std::size_t count=0;
    while(current||top){while(current){stack[top++]=current;current=nodes[current].left;}current=stack[--top];sorted[count++]=nodes[current].key;current=nodes[current].right;}
    const auto required=count*8;if(!output||capacity<required)return -2;for(std::size_t i=0;i<count;++i)put_i64(output,8*i,sorted[i]);return static_cast<std::int64_t>(count);
}
