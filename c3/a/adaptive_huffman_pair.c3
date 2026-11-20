module adaptive_huffman_pair;

const usz ALPHABET = 16, MAX_NODES = 31, MAX_SYMBOLS = 64;
const usz MAX_INPUT = 66, MAX_PACKED = 152;
const int NYT = 0, LEAF = 1, INTERNAL = 2;

struct AhNode { long parent; long left; long right; long symbol; int kind; long weight; }
struct Bits { char[MAX_PACKED] bytes; usz length; }
struct Tree {
    AhNode[MAX_NODES] nodes;
    long node_count; long root; long nyt;
    long[ALPHABET] leaf_of;
    long[MAX_NODES] fgk_order;
    long order_count;
    Bits bits;
}
struct OrderedNode { long id; long depth; long path; }

fn void put_bit(Bits* bits, uint value) {
    if (value != 0) bits->bytes[bits->length / 8] = (char)((uint)bits->bytes[bits->length / 8] | (1u << (7u - (uint)(bits->length % 8))));
    ++bits->length;
}
fn void put_value(Bits* bits, uint value, uint width) { for (uint shift = width; shift > 0; --shift) put_bit(bits, (value >> (shift - 1)) & 1u); }
fn void encode_path(Tree* tree, long node) {
    uint[MAX_NODES] reverse_path = {};
    usz depth = 0;
    while (node != tree->root) { long parent = tree->nodes[node].parent; reverse_path[depth++] = tree->nodes[parent].right == node ? 1u : 0u; node = parent; }
    while (depth > 0) put_bit(&tree->bits, reverse_path[--depth]);
}
fn bool is_ancestor(Tree* tree, long ancestor, long node) {
    for (long parent = tree->nodes[node].parent; parent >= 0; parent = tree->nodes[parent].parent) if (parent == ancestor) return true;
    return false;
}
fn void replace_child(Tree* tree, long parent, long old_child, long new_child) {
    if (tree->nodes[parent].left == old_child) tree->nodes[parent].left = new_child;
    else if (tree->nodes[parent].right == old_child) tree->nodes[parent].right = new_child;
}
fn void swap_positions(Tree* tree, long a, long b, bool update_order) {
    if (a == b || tree->nodes[a].parent == b || tree->nodes[b].parent == a || is_ancestor(tree,a,b) || is_ancestor(tree,b,a)) return;
    long pa = tree->nodes[a].parent, pb = tree->nodes[b].parent;
    if (pa == pb) { if (pa >= 0) { long temp = tree->nodes[pa].left; tree->nodes[pa].left = tree->nodes[pa].right; tree->nodes[pa].right = temp; } }
    else {
        if (pa >= 0) replace_child(tree,pa,a,b);
        if (pb >= 0) replace_child(tree,pb,b,a);
        tree->nodes[a].parent = pb; tree->nodes[b].parent = pa;
    }
    if (tree->root == a) tree->root = b; else if (tree->root == b) tree->root = a;
    if (update_order) {
        long ra = -1, rb = -1;
        for (long i=0;i<tree->order_count;i++) { if (tree->fgk_order[i]==a) ra=i; if (tree->fgk_order[i]==b) rb=i; }
        if (ra>=0 && rb>=0) { tree->fgk_order[ra]=b; tree->fgk_order[rb]=a; }
    }
}
fn void initialize(Tree* tree) {
    *tree = {};
    tree->node_count=1; tree->root=0; tree->nyt=0;
    tree->nodes[0].parent=-1; tree->nodes[0].left=-1; tree->nodes[0].right=-1; tree->nodes[0].symbol=-1; tree->nodes[0].kind=NYT;
    tree->fgk_order[0]=0; tree->order_count=1;
    for (usz i=0;i<ALPHABET;i++) tree->leaf_of[i]=-1;
}
fn long add_node(Tree* tree, long parent, int kind, long symbol) {
    long id=tree->node_count++;
    tree->nodes[id].parent=parent; tree->nodes[id].left=-1; tree->nodes[id].right=-1;
    tree->nodes[id].symbol=symbol; tree->nodes[id].kind=kind; tree->nodes[id].weight=0;
    return id;
}
fn long split_nyt(Tree* tree, long symbol, bool remaining, bool for_fgk) {
    long old=tree->nyt;
    if (!remaining) { tree->nodes[old].kind=LEAF; tree->nodes[old].symbol=symbol; tree->leaf_of[symbol]=old; tree->nyt=-1; return old; }
    long left=add_node(tree,old,NYT,-1); long right=add_node(tree,old,LEAF,symbol);
    tree->nodes[old].kind=INTERNAL; tree->nodes[old].left=left; tree->nodes[old].right=right;
    tree->leaf_of[symbol]=right; tree->nyt=left;
    if (for_fgk) {
        long position=0; while (tree->fgk_order[position]!=old) ++position;
        for (long i=tree->order_count+1;i>position+2;--i) tree->fgk_order[i]=tree->fgk_order[i-2];
        tree->fgk_order[position]=left; tree->fgk_order[position+1]=right; tree->fgk_order[position+2]=old; tree->order_count+=2;
    }
    return right;
}
fn long fgk_leader(Tree* tree, long node, bool leaves_only) {
    long weight=tree->nodes[node].weight, parent=tree->nodes[node].parent;
    for (long i=tree->order_count-1;i>=0;--i) {
        long candidate=tree->fgk_order[i];
        if (candidate==parent || tree->nodes[candidate].weight!=weight || (leaves_only && tree->nodes[candidate].kind==INTERNAL) || is_ancestor(tree,candidate,node) || is_ancestor(tree,node,candidate)) continue;
        return candidate;
    }
    return node;
}
fn void update_fgk(Tree* tree, long node) {
    long parent=tree->nodes[node].parent;
    if (tree->nyt>=0 && parent>=0 && tree->nodes[tree->nyt].parent==parent) {
        swap_positions(tree,node,fgk_leader(tree,node,true),true); ++tree->nodes[node].weight; node=tree->nodes[node].parent;
    }
    while (node!=tree->root) { swap_positions(tree,node,fgk_leader(tree,node,false),true); ++tree->nodes[node].weight; node=tree->nodes[node].parent; }
    ++tree->nodes[tree->root].weight;
}
fn long implicit_order(Tree* tree, OrderedNode* order) {
    for (long id=0;id<tree->node_count;id++) {
        long[MAX_NODES] reverse_path={}; long depth=0, at=id, path=0;
        while (at!=tree->root) { long parent=tree->nodes[at].parent; reverse_path[depth++]=tree->nodes[parent].right==at ? 1 : 0; at=parent; }
        for (long i=depth-1;i>=0;i--) path=path*2+reverse_path[i];
        order[id].id=id; order[id].depth=depth; order[id].path=path;
    }
    for (long i=1;i<tree->node_count;i++) {
        OrderedNode value=order[i]; long j=i;
        while (j>0 && (order[j-1].depth<value.depth || (order[j-1].depth==value.depth && order[j-1].path>value.path))) { order[j]=order[j-1]; --j; }
        order[j]=value;
    }
    return tree->node_count;
}
fn long vitter_leader(Tree* tree, long node, OrderedNode* order) {
    long count=implicit_order(tree,order);
    for (long i=count-1;i>=0;i--) { long id=order[i].id; if (tree->nodes[id].weight==tree->nodes[node].weight && tree->nodes[id].kind==tree->nodes[node].kind) return id; }
    return node;
}
fn long slide_increment(Tree* tree, long node, OrderedNode* order) {
    long old_parent=tree->nodes[node].parent;
    int target_kind=tree->nodes[node].kind==LEAF ? INTERNAL : LEAF;
    long target_weight=tree->nodes[node].weight+(tree->nodes[node].kind==LEAF ? 0 : 1);
    OrderedNode[MAX_NODES] ordered={}; long count=implicit_order(tree,&ordered[0]);
    long[MAX_NODES] block={}; long block_count=0;
    for (long i=0;i<count;i++) { long id=ordered[i].id; if (tree->nodes[id].kind==target_kind && tree->nodes[id].weight==target_weight) block[block_count++]=id; }
    for (long i=0;i<block_count;i++) swap_positions(tree,node,block[i],false);
    ++tree->nodes[node].weight;
    return tree->nodes[node].kind==LEAF ? tree->nodes[node].parent : old_parent;
}
fn void update_vitter(Tree* tree, long node, bool just_split) {
    OrderedNode[MAX_NODES] order={}; long leaf_to_increment=-1;
    if (just_split) { leaf_to_increment=node; node=tree->nodes[node].parent; }
    else {
        swap_positions(tree,node,vitter_leader(tree,node,&order[0]),false);
        long parent=tree->nodes[node].parent;
        if (tree->nyt>=0 && parent>=0 && tree->nodes[tree->nyt].parent==parent) { leaf_to_increment=node; node=parent; }
    }
    while (node!=tree->root) node=slide_increment(tree,node,&order[0]);
    if (leaf_to_increment>=0) (void)slide_increment(tree,leaf_to_increment,&order[0]);
    ++tree->nodes[tree->root].weight;
}
fn long run(long* input, usz length, char* output, usz capacity, bool vitter) {
    if (input==null || length<1 || length>MAX_INPUT) return -1;
    long n_value=input[0];
    if (n_value<0 || n_value>MAX_SYMBOLS || length!=1+(usz)n_value) return -1;
    for (usz i=0;i<(usz)n_value;i++) if (input[i+1]<0 || input[i+1]>=(long)ALPHABET) return -1;
    Tree tree={}; initialize(&tree); long seen=0;
    for (usz i=0;i<(usz)n_value;i++) {
        long symbol=input[i+1]; bool is_new=tree.leaf_of[symbol]<0;
        long current=is_new ? tree.nyt : tree.leaf_of[symbol]; if (current<0) return -1;
        encode_path(&tree,current);
        if (is_new) put_value(&tree.bits,(uint)symbol,4);
        bool just_split=false;
        if (is_new) { ++seen; just_split=seen<(long)ALPHABET; current=split_nyt(&tree,symbol,just_split,!vitter); }
        if (vitter) update_vitter(&tree,current,just_split); else update_fgk(&tree,current);
    }
    usz packed=(tree.bits.length+7)/8, required=8+packed;
    if (output==null || capacity<required) return -2;
    ulong count=(ulong)tree.bits.length;
    for (usz i=0;i<8;i++) output[i]=(char)(count>>(8*i));
    for (usz i=0;i<packed;i++) output[8+i]=tree.bits.bytes[i];
    return (long)required;
}
fn long fgk_adaptive_huffman(long* input, usz length, char* output, usz capacity)
		@export("fgk_adaptive_huffman") { return run(input,length,output,capacity,false); }
fn long vitter_adaptive_huffman(long* input, usz length, char* output, usz capacity)
		@export("vitter_adaptive_huffman") { return run(input,length,output,capacity,true); }
