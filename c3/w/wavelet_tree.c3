module wavelet_tree;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* ptr);

const usz MAX_N=64;
const usz MAX_Q=128;
const usz MAX_NODES=768;
struct Node { long low; long high; int left; int right; usz size; usz[65] prefix; }

fn int build(Node* nodes, int* used, long* values, usz length, long low, long high) {
    int id=*used; *used=*used+1;
    nodes[id].low=low; nodes[id].high=high; nodes[id].left=-1; nodes[id].right=-1; nodes[id].size=length;
    nodes[id].prefix[0]=0;
    if (low==high || length==0) return id;
    long mid=low+(high-low)/2;
    long[64] left_values; long[64] right_values; usz left_count=0; usz right_count=0;
    for (usz i=0;i<length;i++) {
        if (values[i]<=mid) { left_values[left_count++]=values[i]; }
        else { right_values[right_count++]=values[i]; }
        nodes[id].prefix[i+1]=left_count;
    }
    if (left_count>0) nodes[id].left=build(nodes,used,&left_values[0],left_count,low,mid);
    if (right_count>0) nodes[id].right=build(nodes,used,&right_values[0],right_count,mid+1,high);
    return id;
}
fn long rank_prefix(Node* nodes,int id,long value,usz count) {
    if (id<0 || count==0) return 0;
    Node* node=&nodes[id];
    if (node.low==node.high) return node.low==value?(long)count:0;
    long mid=node.low+(node.high-node.low)/2; usz left_count=node.prefix[count];
    if (value<=mid) return rank_prefix(nodes,node.left,value,left_count);
    return rank_prefix(nodes,node.right,value,count-left_count);
}
fn long quantile(Node* nodes,int id,usz left,usz right,usz k) {
    Node* node=&nodes[id];
    if (node.low==node.high) return node.low;
    usz left_before=node.prefix[left];
    usz left_after=node.prefix[right];
    usz in_left=left_after-left_before;
    if (k<in_left) return quantile(nodes,node.left,left_before,left_after,k);
    return quantile(nodes,node.right,left-left_before,right-left_after,k-in_left);
}
fn long range_count(Node* nodes,int id,usz left,usz right,long low,long high) {
    if (id<0 || left>=right) return 0;
    Node* node=&nodes[id];
    if (high<node.low || low>node.high) return 0;
    if (low<=node.low && node.high<=high) return (long)(right-left);
    if (node.low==node.high) return 0;
    usz left_before=node.prefix[left];
    usz left_after=node.prefix[right];
    return range_count(nodes,node.left,left_before,left_after,low,high)+range_count(nodes,node.right,left-left_before,right-left_after,low,high);
}
fn long wavelet_tree_benchmark(long* values, usz length) @export("wavelet_tree_benchmark") {
    if (values==null || length<3 || length>MAX_N+2+5*MAX_Q || values[0]<1 || values[0]>(long)MAX_N) return -1;
    usz n=(usz)values[0]; if (length<n+2) return -1;
    long low=values[1];
    long high=values[1];
    for (usz i=0;i<n;i++) { if(values[i+1]<-1000 || values[i+1]>1000)return -1; if(values[i+1]<low)low=values[i+1];if(values[i+1]>high)high=values[i+1]; }
    long qv=values[n+1]; if(qv<0 || qv>(long)MAX_Q || length!=n+2+5*(usz)qv)return -1;
    Node* nodes=(Node*)calloc(MAX_NODES, 552);
    if(nodes==null)return -1;
    int used=0;
    int root=build(nodes,&used,values+1,n,low,high);
    long total=0;
    for(usz j=0;j<(usz)qv;j++){
        usz p=n+2+5*j;
        long op=values[p];
        long a=values[p+1];
        long b=values[p+2];
        long c=values[p+3];
        long d=values[p+4];
        long answer=0;
        if(op==0){if(a< -1000||a>1000||b< -1||b>=(long)n){free(nodes);return -1;}answer=rank_prefix(nodes,root,a,(usz)(b+1));}
        else if(op==1){if(a<0||b<a||b>=(long)n||c<0||c>b-a){free(nodes);return -1;}answer=quantile(nodes,root,(usz)a,(usz)(b+1),(usz)c);}
        else if(op==2){if(a<0||b<a||b>=(long)n||c>d||c< -1000||d>1000){free(nodes);return -1;}answer=range_count(nodes,root,(usz)a,(usz)(b+1),c,d);}
        else {free(nodes);return -1;}
        total+=(long)(j+1)*(answer+1000001);
    }
    free(nodes);
    return total;
}
