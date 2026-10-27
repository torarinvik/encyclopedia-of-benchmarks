module mmpfh_compacted_trie_rank;
const long K=16, Q=16, NN=31, OUT=174;
struct Node { int bit, left, right, leaves; uint key, low, high; }
Node[NN] nodes;
uint[K] keys;
int node_count;
fn int build(int lo, int hi, int width) {
    int id=node_count; node_count++;
    if (hi-lo==1) { nodes[id]=Node{-1,-1,-1,1,keys[lo],keys[lo],keys[lo]}; return id; }
    uint diff=keys[lo]^keys[hi-1]; int bit=width-1;
    while (((diff >> bit)&1)!=1) bit--;
    int split=lo; while(split<hi && ((keys[split]>>bit)&1)==0) split++;
    nodes[id].bit=width-1-bit; nodes[id].low=keys[lo];nodes[id].high=keys[hi-1];nodes[id].left=build(lo,split,width); nodes[id].right=build(split,hi,width);
    nodes[id].leaves=nodes[nodes[id].left].leaves+nodes[nodes[id].right].leaves; nodes[id].key=0; return id;
}
fn int rank_key(uint q, int width) {
    int id=0, rank=0;
    while(true) { if(q<nodes[id].low)return rank;if(q>nodes[id].high)return rank+nodes[id].leaves;if(nodes[id].bit<0)return rank;int shift=width-1-nodes[id].bit;if(((q>>shift)&1)==1){rank+=nodes[nodes[id].left].leaves;id=nodes[id].right;}else{id=nodes[id].left;} }
}
fn void put_i64(char* out, usz pos, long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[pos+b]=(char)((bits>>(8*b))&255);}
fn long mmpfh_compacted_trie_rank(long* input, usz length, char* output, usz capacity) @export("mmpfh_compacted_trie_rank") {
    if(input==null || length<3 || length>35)return -1;
    long w0=input[0],d0=input[1],q0=input[2];
    if(w0<1||w0>16||d0<1||d0>K||q0<1||q0>Q||length!=3+(d0+q0).usz())return -1;
    ulong limit=1ul << w0.usz();
    for(int i=0;i<d0.int();i++){long x=input[3+i];if(x<0||(ulong)x>=limit||(i>0&&x<=input[2+i]))return -1;keys[i]=(uint)x;}
    for(int i=0;i<q0.int();i++){long x=input[3+d0+i];if(x<0||(ulong)x>=limit)return -1;}
    node_count=0;build(0,d0.int(),w0.int());
    long[OUT] staged;usz used=0;staged[used++]=d0;staged[used++]=node_count;staged[used++]=q0;
    for(int i=0;i<node_count;i++){staged[used++]=nodes[i].bit;staged[used++]=nodes[i].left;staged[used++]=nodes[i].right;staged[used++]=nodes[i].low;staged[used++]=nodes[i].high;}
    for(int i=0;i<q0.int();i++)staged[used++]=rank_key((uint)input[3+d0+i],w0.int());
    usz required=used*8;if(output==null||capacity<required)return -2;
    for(usz i=0;i<used;i++)put_i64(output,i*8,staged[i]);return required.long();
}
