module range_add_range_min;

struct Tree { long[256] minimum; long[256] lazy; }

fn void build(Tree* t, long* input, int node, int left, int right) {
    if (right-left==1) { t.minimum[node]=input[2+left]; return; }
    int middle=(left+right)/2;
    build(t,input,2*node,left,middle);
    build(t,input,2*node+1,middle,right);
    long a=t.minimum[2*node], b=t.minimum[2*node+1];
    t.minimum[node]=a<b ? a : b;
}
fn void push(Tree* t, int node) {
    for (int child=2*node;child<=2*node+1;child++) {
        t.minimum[child]+=t.lazy[node]; t.lazy[child]+=t.lazy[node];
    }
    t.lazy[node]=0;
}
fn void add(Tree* t, int node, int left, int right, int first, int last, long delta) {
    if (last<=left || right<=first) return;
    if (first<=left && right<=last) { t.minimum[node]+=delta; t.lazy[node]+=delta; return; }
    push(t,node);
    int middle=(left+right)/2;
    add(t,2*node,left,middle,first,last,delta);
    add(t,2*node+1,middle,right,first,last,delta);
    long a=t.minimum[2*node], b=t.minimum[2*node+1];
    t.minimum[node]=a<b ? a : b;
}
fn long query(Tree* t, int node, int left, int right, int first, int last) {
    if (last<=left || right<=first) return 9223372036854775807;
    if (first<=left && right<=last) return t.minimum[node];
    push(t,node);
    int middle=(left+right)/2;
    long a=query(t,2*node,left,middle,first,last);
    long b=query(t,2*node+1,middle,right,first,last);
    return a<b ? a : b;
}
fn long range_add_range_min(long* input, usz length, uchar* output, usz capacity) @export("range_add_range_min") {
    if (input==null || length<2 || length>322 || input[0]<1 || input[0]>64 || input[1]<1 || input[1]>64) return -1;
    int n=(int)input[0], q=(int)input[1], queries=0;
    if (length!=(usz)(2+n+4*q)) return -1;
    for (int i=0;i<n;i++) if (input[2+i]<-1000000 || input[2+i]>1000000) return -1;
    for (int i=0;i<q;i++) {
        int base=2+n+4*i;
        long op=input[base], left=input[base+1], right=input[base+2], delta=input[base+3];
        if (left<0 || left>=right || right>n) return -1;
        if (op==0) { if (delta < -100000 || delta > 100000) return -1; }
        else if (op==1) { if (delta!=0) return -1; queries++; }
        else return -1;
    }
    if (queries==0) return -1;
    if (output==null || capacity<(usz)(8*queries)) return -2;
    Tree tree={}; build(&tree,input,1,0,n);
    int written=0;
    for (int i=0;i<q;i++) {
        int base=2+n+4*i, left=(int)input[base+1], right=(int)input[base+2];
        if (input[base]==0) add(&tree,1,0,n,left,right,input[base+3]);
        else {
            ulong bits=(ulong)query(&tree,1,0,n,left,right);
            for (int byte=0;byte<8;byte++) output[8*written+byte]=(uchar)(bits >> (8*byte));
            written++;
        }
    }
    return 8*written;
}
