module dynamic_sequence_range_affine_range_sum;

const long MOD=998244353;
const usz MAX_N=32,MAX_Q=32,MAX_NODES=64,MAX_INPUT=195;
const int NONE=-1;
struct Node { int left; int right; int size; long value; long sum; long mul; long add; uint64 priority; bool reversed; }
struct Operation { int kind; int left; int right; int node; long mul; long add; }

fn uint64 priority_for(usz id){long state=1;for(usz i=0;i<=id;i+=1)state=state*48271%2147483647;return (uint64)state;}
fn int node_size(Node[MAX_NODES]*t,int x){return x<0?0:t[x].size;}
fn long node_sum(Node[MAX_NODES]*t,int x){return x<0?0:t[x].sum;}
fn bool higher(Node[MAX_NODES]*t,int a,int b){return t[a].priority!=t[b].priority?t[a].priority>t[b].priority:a>b;}
fn void pull(Node[MAX_NODES]*t,int x){t[x].size=1+node_size(t,t[x].left)+node_size(t,t[x].right);t[x].sum=(t[x].value+node_sum(t,t[x].left)+node_sum(t,t[x].right))%MOD;}
fn void affine(Node[MAX_NODES]*t,int x,long m,long a){if(x<0)return;t[x].value=(m*t[x].value+a)%MOD;t[x].sum=(m*t[x].sum+a*t[x].size)%MOD;t[x].mul=m*t[x].mul%MOD;t[x].add=(m*t[x].add+a)%MOD;}
fn void reverse_node(Node[MAX_NODES]*t,int x){if(x<0)return;int child=t[x].left;t[x].left=t[x].right;t[x].right=child;t[x].reversed=!t[x].reversed;}
fn void push(Node[MAX_NODES]*t,int x){if(t[x].mul!=1||t[x].add!=0){affine(t,t[x].left,t[x].mul,t[x].add);affine(t,t[x].right,t[x].mul,t[x].add);t[x].mul=1;t[x].add=0;}if(t[x].reversed){reverse_node(t,t[x].left);reverse_node(t,t[x].right);t[x].reversed=false;}}
fn void split(Node[MAX_NODES]*t,int root,int count,int*first,int*second){if(root<0){*first=NONE;*second=NONE;return;}push(t,root);if(node_size(t,t[root].left)>=count){int a,b;split(t,t[root].left,count,&a,&b);t[root].left=b;pull(t,root);*first=a;*second=root;}else{int a,b;split(t,t[root].right,count-node_size(t,t[root].left)-1,&a,&b);t[root].right=a;pull(t,root);*first=root;*second=b;}}
fn int merge(Node[MAX_NODES]*t,int a,int b){if(a<0)return b;if(b<0)return a;if(higher(t,a,b)){push(t,a);t[a].right=merge(t,t[a].right,b);pull(t,a);return a;}push(t,b);t[b].left=merge(t,a,t[b].left);pull(t,b);return b;}
fn void put64(uint8*out,usz at,long value){uint64 bits=(uint64)value;for(usz j=0;j<8;j+=1)out[at+j]=(uint8)(bits>>(8*j));}

fn long dynamic_sequence_range_affine_range_sum(long*input,usz length,uint8*output,usz capacity) @export("dynamic_sequence_range_affine_range_sum") {
    if(input==null||length<2||length>MAX_INPUT)return -1;long n64=input[0],q64=input[1];if(n64<0||n64>MAX_N||q64<0||q64>MAX_Q)return -1;usz n=(usz)n64,q=(usz)q64,offset=2;if(length<2+n)return -1;
    Node[MAX_NODES] nodes=zeroed;
    for(usz i=0;i<n;i+=1){long value=input[offset];offset+=1;if(value<0||value>=MOD)return -1;nodes[i]=Node{NONE,NONE,1,value,value,1,0,priority_for(i),false};}
    Operation[MAX_Q] ops=zeroed;usz current=n,node_count=n,query_count=0;
    for(usz i=0;i<q;i+=1){if(offset>=length)return -1;long tag=input[offset];offset+=1;if(tag<0||tag>4)return -1;Operation op=Operation{(int)tag,0,0,NONE,0,0};
        if(tag==0){if(offset+2>length)return -1;long at=input[offset],value=input[offset+1];offset+=2;if(at<0||(uint64)at>current||current>=MAX_NODES||value<0||value>=MOD)return -1;op.left=(int)at;op.node=(int)node_count;nodes[node_count]=Node{NONE,NONE,1,value,value,1,0,priority_for(node_count),false};node_count+=1;current+=1;}
        else if(tag==1){if(offset>=length)return -1;long at=input[offset];offset+=1;if(at<0||(uint64)at>=current)return -1;op.left=(int)at;current-=1;}
        else if(tag==2||tag==4){if(offset+2>length)return -1;long l=input[offset],r=input[offset+1];offset+=2;if(l<0||l>r||(uint64)r>current)return -1;op.left=(int)l;op.right=(int)r;if(tag==4)query_count+=1;}
        else{if(offset+4>length)return -1;long l=input[offset],r=input[offset+1],m=input[offset+2],a=input[offset+3];offset+=4;if(l<0||l>r||(uint64)r>current||m<0||m>=MOD||a<0||a>=MOD)return -1;op.left=(int)l;op.right=(int)r;op.mul=m;op.add=a;}
        ops[i]=op;
    }
    if(offset!=length)return -1;int root=NONE;for(usz i=0;i<n;i+=1)root=merge(&nodes,root,(int)i);long[MAX_Q] answers=zeroed;usz answer_count=0;
    for(usz i=0;i<q;i+=1){Operation op=ops[i];int prefix,suffix,middle;split(&nodes,root,op.left,&prefix,&suffix);if(op.kind==0){root=merge(&nodes,merge(&nodes,prefix,op.node),suffix);continue;}if(op.kind==1){split(&nodes,suffix,1,&middle,&suffix);root=merge(&nodes,prefix,suffix);continue;}split(&nodes,suffix,op.right-op.left,&middle,&suffix);if(op.kind==2)reverse_node(&nodes,middle);else if(op.kind==3)affine(&nodes,middle,op.mul,op.add);else{answers[answer_count]=node_sum(&nodes,middle);answer_count+=1;}root=merge(&nodes,merge(&nodes,prefix,middle),suffix);}
    usz bytes=8*query_count;if(output==null||capacity<bytes)return -2;for(usz i=0;i<query_count;i+=1)put64(output,8*i,answers[i]);return (long)bytes;
}
