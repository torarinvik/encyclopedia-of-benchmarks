#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int alphabet = 16, max_nodes = 31, max_symbols = 64;
constexpr std::size_t max_input = 66, max_packed = 152;
enum Kind { nyt_kind, leaf_kind, internal_kind };

struct Node { int parent=-1, left=-1, right=-1, symbol=-1, kind=nyt_kind; std::int64_t weight=0; };
struct Bits { std::array<std::uint8_t,max_packed> bytes{}; std::size_t size=0; };
struct Tree {
    std::array<Node,max_nodes> nodes{};
    int node_count=1, root=0, nyt=0;
    std::array<int,alphabet> leaf_of{};
    std::array<int,max_nodes> fgk_order{};
    int order_count=1;
    Bits bits{};
};
struct OrderedNode { int id, depth, path; };

void put_bit(Bits& bits, unsigned value) {
    if (value) bits.bytes[bits.size/8] |= static_cast<std::uint8_t>(1u << (7u-static_cast<unsigned>(bits.size%8)));
    ++bits.size;
}
void put_value(Bits& bits, unsigned value, unsigned width) {
    for (unsigned shift=width; shift>0; --shift) put_bit(bits,(value>>(shift-1))&1u);
}
void encode_path(Tree& tree, int node) {
    std::array<unsigned,max_nodes> reverse{};
    std::size_t depth=0;
    while (node!=tree.root) {
        const int parent=tree.nodes[node].parent;
        reverse[depth++]=static_cast<unsigned>(tree.nodes[parent].right==node);
        node=parent;
    }
    while (depth) put_bit(tree.bits, reverse[--depth]);
}
bool is_ancestor(const Tree& tree, int ancestor, int node) {
    for (int parent=tree.nodes[node].parent; parent>=0; parent=tree.nodes[parent].parent)
        if (parent==ancestor) return true;
    return false;
}
void replace_child(Tree& tree, int parent, int old_child, int new_child) {
    if (tree.nodes[parent].left==old_child) tree.nodes[parent].left=new_child;
    else if (tree.nodes[parent].right==old_child) tree.nodes[parent].right=new_child;
}
void swap_positions(Tree& tree, int a, int b, bool update_order) {
    if (a==b || tree.nodes[a].parent==b || tree.nodes[b].parent==a ||
        is_ancestor(tree,a,b) || is_ancestor(tree,b,a)) return;
    const int pa=tree.nodes[a].parent, pb=tree.nodes[b].parent;
    if (pa==pb) {
        if (pa>=0) std::swap(tree.nodes[pa].left,tree.nodes[pa].right);
    } else {
        if (pa>=0) replace_child(tree,pa,a,b);
        if (pb>=0) replace_child(tree,pb,b,a);
        tree.nodes[a].parent=pb; tree.nodes[b].parent=pa;
    }
    if (tree.root==a) tree.root=b; else if (tree.root==b) tree.root=a;
    if (update_order) {
        auto ia=std::find(tree.fgk_order.begin(),tree.fgk_order.begin()+tree.order_count,a);
        auto ib=std::find(tree.fgk_order.begin(),tree.fgk_order.begin()+tree.order_count,b);
        if (ia!=tree.fgk_order.begin()+tree.order_count && ib!=tree.fgk_order.begin()+tree.order_count) std::iter_swap(ia,ib);
    }
}
void initialize(Tree& tree) {
    tree=Tree{};
    tree.nodes[0]=Node{-1,-1,-1,-1,nyt_kind,0};
    tree.fgk_order[0]=0;
    tree.leaf_of.fill(-1);
}
int add_node(Tree& tree, int parent, int kind, int symbol) {
    const int id=tree.node_count++;
    tree.nodes[id]=Node{parent,-1,-1,symbol,kind,0};
    return id;
}
int split_nyt(Tree& tree, int symbol, bool remaining, bool for_fgk) {
    const int old=tree.nyt;
    if (!remaining) {
        tree.nodes[old].kind=leaf_kind;
        tree.nodes[old].symbol=symbol;
        tree.leaf_of[symbol]=old;
        tree.nyt=-1;
        return old;
    }
    const int left=add_node(tree,old,nyt_kind,-1);
    const int right=add_node(tree,old,leaf_kind,symbol);
    tree.nodes[old].kind=internal_kind;
    tree.nodes[old].left=left; tree.nodes[old].right=right;
    tree.leaf_of[symbol]=right; tree.nyt=left;
    if (for_fgk) {
        int position=0;
        while (tree.fgk_order[position]!=old) ++position;
        for (int i=tree.order_count+1;i>position+2;--i) tree.fgk_order[i]=tree.fgk_order[i-2];
        tree.fgk_order[position]=left; tree.fgk_order[position+1]=right; tree.fgk_order[position+2]=old;
        tree.order_count+=2;
    }
    return right;
}
int fgk_leader(const Tree& tree, int node, bool leaves_only=false) {
    const auto weight=tree.nodes[node].weight;
    const int parent=tree.nodes[node].parent;
    for (int i=tree.order_count-1;i>=0;--i) {
        const int candidate=tree.fgk_order[i];
        if (candidate==parent || tree.nodes[candidate].weight!=weight ||
            (leaves_only && tree.nodes[candidate].kind==internal_kind) ||
            is_ancestor(tree,candidate,node) || is_ancestor(tree,node,candidate)) continue;
        return candidate;
    }
    return node;
}
void update_fgk(Tree& tree, int node) {
    const int parent=tree.nodes[node].parent;
    if (tree.nyt>=0 && parent>=0 && tree.nodes[tree.nyt].parent==parent) {
        swap_positions(tree,node,fgk_leader(tree,node,true),true);
        ++tree.nodes[node].weight;
        node=tree.nodes[node].parent;
    }
    while (node!=tree.root) {
        swap_positions(tree,node,fgk_leader(tree,node),true);
        ++tree.nodes[node].weight;
        node=tree.nodes[node].parent;
    }
    ++tree.nodes[tree.root].weight;
}
int implicit_order(Tree& tree, std::array<OrderedNode,max_nodes>& order) {
    for (int id=0;id<tree.node_count;++id) {
        std::array<int,max_nodes> reverse{}; int depth=0, at=id, path=0;
        while (at!=tree.root) { const int parent=tree.nodes[at].parent; reverse[depth++]=tree.nodes[parent].right==at; at=parent; }
        for (int i=depth-1;i>=0;--i) path=path*2+reverse[i];
        order[id]=OrderedNode{id,depth,path};
    }
    std::sort(order.begin(),order.begin()+tree.node_count,[](const OrderedNode& a,const OrderedNode& b){
        if (a.depth!=b.depth) return a.depth>b.depth;
        return a.path<b.path;
    });
    return tree.node_count;
}
int vitter_leader(Tree& tree, int node, std::array<OrderedNode,max_nodes>& order) {
    const int count=implicit_order(tree,order);
    for (int i=count-1;i>=0;--i) { const int id=order[i].id; if (tree.nodes[id].weight==tree.nodes[node].weight && tree.nodes[id].kind==tree.nodes[node].kind) return id; }
    return node;
}
int slide_increment(Tree& tree, int node, std::array<OrderedNode,max_nodes>& ordered) {
    const int old_parent=tree.nodes[node].parent;
    const int target_kind=tree.nodes[node].kind==leaf_kind ? internal_kind : leaf_kind;
    const auto target_weight=tree.nodes[node].weight+(tree.nodes[node].kind==leaf_kind ? 0 : 1);
    const int count=implicit_order(tree,ordered);
    std::array<int,max_nodes> block{}; int block_count=0;
    for (int i=0;i<count;++i) { const int id=ordered[i].id; if (tree.nodes[id].kind==target_kind && tree.nodes[id].weight==target_weight) block[block_count++]=id; }
    for (int i=0;i<block_count;++i) swap_positions(tree,node,block[i],false);
    ++tree.nodes[node].weight;
    return tree.nodes[node].kind==leaf_kind ? tree.nodes[node].parent : old_parent;
}
void update_vitter(Tree& tree, int node, bool just_split) {
    std::array<OrderedNode,max_nodes> ordered{};
    int leaf_to_increment=-1;
    if (just_split) { leaf_to_increment=node; node=tree.nodes[node].parent; }
    else {
        swap_positions(tree,node,vitter_leader(tree,node,ordered),false);
        const int parent=tree.nodes[node].parent;
        if (tree.nyt>=0 && parent>=0 && tree.nodes[tree.nyt].parent==parent) { leaf_to_increment=node; node=parent; }
    }
    while (node!=tree.root) node=slide_increment(tree,node,ordered);
    if (leaf_to_increment>=0) (void)slide_increment(tree,leaf_to_increment,ordered);
    ++tree.nodes[tree.root].weight;
}
int run(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity,bool vitter) {
    if (input==nullptr || length<1 || length>max_input) return -1;
    const auto n_value=input[0];
    if (n_value<0 || n_value>max_symbols || length!=1+static_cast<std::size_t>(n_value)) return -1;
    for (std::size_t i=0;i<static_cast<std::size_t>(n_value);++i) if (input[i+1]<0 || input[i+1]>=alphabet) return -1;
    Tree tree; initialize(tree); int seen=0;
    for (std::size_t i=0;i<static_cast<std::size_t>(n_value);++i) {
        const int symbol=static_cast<int>(input[i+1]);
        const bool is_new=tree.leaf_of[symbol]<0;
        int current=is_new ? tree.nyt : tree.leaf_of[symbol];
        if (current<0) return -1;
        encode_path(tree,current);
        if (is_new) put_value(tree.bits,static_cast<unsigned>(symbol),4);
        bool just_split=false;
        if (is_new) { ++seen; just_split=seen<alphabet; current=split_nyt(tree,symbol,just_split,!vitter); }
        if (vitter) update_vitter(tree,current,just_split); else update_fgk(tree,current);
    }
    const auto packed=(tree.bits.size+7)/8;
    const auto required=8+packed;
    if (output==nullptr || capacity<required) return -2;
    const auto count=static_cast<std::uint64_t>(tree.bits.size);
    for (std::size_t i=0;i<8;++i) output[i]=static_cast<std::uint8_t>(count>>(8*i));
    for (std::size_t i=0;i<packed;++i) output[8+i]=tree.bits.bytes[i];
    return static_cast<int>(required);
}
}

extern "C" std::int64_t fgk_adaptive_huffman(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) { return run(input,length,output,capacity,false); }
extern "C" std::int64_t vitter_adaptive_huffman(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) { return run(input,length,output,capacity,true); }
