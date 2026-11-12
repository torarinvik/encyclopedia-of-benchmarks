module range_set_range_composite;

const usz MAX_N=64,MAX_Q=32,TREE_N=4*MAX_N+5;
const long MOD=998244353;
struct Affine { long a; long b; }
struct Node { Affine value; Affine lazy; bool has; }
struct Operation { int kind; usz left; usz right; long x; long y; }

fn Affine compose(Affine after,Affine before){return Affine{after.a*before.a%MOD,(after.a*before.b+after.b)%MOD};}
fn Affine power_map(long a,long b,usz exponent){Affine result=Affine{1,0},base=Affine{a,b};while(exponent>0){if(exponent&1)result=compose(base,result);base=compose(base,base);exponent>>=1;}return result;}
fn void build(Node[TREE_N]*tree,usz node,usz left,usz right,long[MAX_N]*ia,long[MAX_N]*ib){if(right-left==1){tree[node].value=Affine{ia[left],ib[left]};return;}usz mid=left+(right-left)/2;build(tree,node*2,left,mid,ia,ib);build(tree,node*2+1,mid,right,ia,ib);tree[node].value=compose(tree[node*2+1].value,tree[node*2].value);}
fn void apply(Node[TREE_N]*tree,usz node,usz left,usz right,long a,long b){tree[node].value=power_map(a,b,right-left);tree[node].lazy=Affine{a,b};tree[node].has=true;}
fn void push(Node[TREE_N]*tree,usz node,usz left,usz right){if(!tree[node].has||right-left==1)return;usz mid=left+(right-left)/2;Affine tag=tree[node].lazy;apply(tree,node*2,left,mid,tag.a,tag.b);apply(tree,node*2+1,mid,right,tag.a,tag.b);tree[node].has=false;}
fn void update(Node[TREE_N]*tree,usz node,usz left,usz right,usz ql,usz qr,long a,long b){if(ql<=left&&right<=qr){apply(tree,node,left,right,a,b);return;}push(tree,node,left,right);usz mid=left+(right-left)/2;if(ql<mid)update(tree,node*2,left,mid,ql,qr,a,b);if(qr>mid)update(tree,node*2+1,mid,right,ql,qr,a,b);tree[node].value=compose(tree[node*2+1].value,tree[node*2].value);}
fn Affine query(Node[TREE_N]*tree,usz node,usz left,usz right,usz ql,usz qr){if(ql<=left&&right<=qr)return tree[node].value;push(tree,node,left,right);usz mid=left+(right-left)/2;if(qr<=mid)return query(tree,node*2,left,mid,ql,qr);if(ql>=mid)return query(tree,node*2+1,mid,right,ql,qr);return compose(query(tree,node*2+1,mid,right,ql,qr),query(tree,node*2,left,mid,ql,qr));}
fn void put64(uint8*out,usz at,long value){uint64 bits=(uint64)value;for(usz b=0;b<8;b+=1)out[at+b]=(uint8)(bits>>(8*b));}

fn long range_set_range_composite(long*input,usz length,uint8*output,usz capacity) @export("range_set_range_composite"){
    if(input==null||length<2||length>291)return -1;long n64=input[0],q64=input[1];if(n64<1||n64>64||q64<1||q64>32)return -1;usz n=(usz)n64,q=(usz)q64,off=2;if(length<2+2*n)return -1;
    long[MAX_N] ia,ib;for(usz i=0;i<n;i+=1){ia[i]=input[off];ib[i]=input[off+1];off+=2;if(ia[i]<1||ia[i]>=MOD||ib[i]<0||ib[i]>=MOD)return -1;}
    Operation[MAX_Q] ops;usz query_count=0;
    for(usz k=0;k<q;k+=1){if(off>=length)return -1;long kind=input[off];off+=1;if(kind==0){if(off+4>length)return -1;long l=input[off],r=input[off+1],a=input[off+2],b=input[off+3];off+=4;if(l<0||l>=r||r>n64||a<1||a>=MOD||b<0||b>=MOD)return -1;ops[k]=Operation{0,(usz)l,(usz)r,a,b};}else if(kind==1){if(off+3>length)return -1;long l=input[off],r=input[off+1],x=input[off+2];off+=3;if(l<0||l>=r||r>n64||x<0||x>=MOD)return -1;ops[k]=Operation{1,(usz)l,(usz)r,x,0};query_count+=1;}else return -1;}
    if(off!=length)return -1;Node[TREE_N] tree=zeroed;build(&tree,1,0,n,&ia,&ib);long[MAX_Q] answers=zeroed;usz out=0;
    for(usz k=0;k<q;k+=1){Operation op=ops[k];if(op.kind==0)update(&tree,1,0,n,op.left,op.right,op.x,op.y);else{Affine z=query(&tree,1,0,n,op.left,op.right);answers[out]=(z.a*op.x+z.b)%MOD;out+=1;}}
    usz bytes=8*query_count;if(output==null||capacity<bytes)return -2;for(usz i=0;i<query_count;i+=1)put64(output,8*i,answers[i]);return (long)bytes;
}
