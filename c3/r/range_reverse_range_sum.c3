module range_reverse_range_sum;

const usz MAX_N=64,MAX_Q=32,MAX_INPUT=163;
struct Node { int left; int right; int size; long value; long sum; uint64 priority; bool reversed; }
struct Operation { int kind; int left; int right; }

fn uint64 priority_for(usz index){long state=1;for(usz i=0;i<=index;i+=1)state=state*48271%2147483647;return (uint64)state;}
fn int sz(Node[MAX_N]*t,int x){return x<0?0:t[x].size;}
fn long sm(Node[MAX_N]*t,int x){return x<0?0:t[x].sum;}
fn bool higher(Node[MAX_N]*t,int a,int b){return t[a].priority!=t[b].priority?t[a].priority>t[b].priority:a>b;}
fn void pull(Node[MAX_N]*t,int x){t[x].size=1+sz(t,t[x].left)+sz(t,t[x].right);t[x].sum=t[x].value+sm(t,t[x].left)+sm(t,t[x].right);}
fn void reverse_node(Node[MAX_N]*t,int x){if(x<0)return;int v=t[x].left;t[x].left=t[x].right;t[x].right=v;t[x].reversed=!t[x].reversed;}
fn void push(Node[MAX_N]*t,int x){if(!t[x].reversed)return;reverse_node(t,t[x].left);reverse_node(t,t[x].right);t[x].reversed=false;}
fn void split(Node[MAX_N]*t,int root,int count,int*first,int*second){if(root<0){*first=-1;*second=-1;return;}push(t,root);if(sz(t,t[root].left)>=count){int a,b;split(t,t[root].left,count,&a,&b);t[root].left=b;pull(t,root);*first=a;*second=root;}else{int a,b;split(t,t[root].right,count-sz(t,t[root].left)-1,&a,&b);t[root].right=a;pull(t,root);*first=root;*second=b;}}
fn int merge(Node[MAX_N]*t,int a,int b){if(a<0)return b;if(b<0)return a;if(higher(t,a,b)){push(t,a);t[a].right=merge(t,t[a].right,b);pull(t,a);return a;}push(t,b);t[b].left=merge(t,a,t[b].left);pull(t,b);return b;}
fn void put64(uint8*out,usz offset,long value){uint64 bits=(uint64)value;for(usz j=0;j<8;j+=1)out[offset+j]=(uint8)(bits>>(8*j));}

fn long range_reverse_range_sum(long*input,usz length,uint8*output,usz capacity) @export("range_reverse_range_sum") {
    if(input==null||length<2||length>MAX_INPUT)return -1;long n64=input[0],q64=input[1];if(n64<0||n64>64||q64<0||q64>32)return -1;usz n=(usz)n64,q=(usz)q64,offset=2;if(length<2+n)return -1;
    Node[MAX_N] nodes=zeroed;
    for(usz i=0;i<n;i+=1){long value=input[offset];offset+=1;if(value<0||value>1000000000)return -1;nodes[i]=Node{-1,-1,1,value,value,priority_for(i),false};}
    Operation[MAX_Q] ops;usz query_count=0;
    for(usz i=0;i<q;i+=1){if(offset+3>length)return -1;long kind=input[offset],l=input[offset+1],r=input[offset+2];offset+=3;if((kind!=0&&kind!=1)||l<0||l>r||r>n64)return -1;ops[i]=Operation{(int)kind,(int)l,(int)r};if(kind==1)query_count+=1;}
    if(offset!=length)return -1;int root=-1;for(usz i=0;i<n;i+=1)root=merge(&nodes,root,(int)i);long[MAX_Q] answers=zeroed;usz answer_count=0;
    for(usz i=0;i<q;i+=1){Operation op=ops[i];int prefix,rest,middle,suffix;split(&nodes,root,op.right,&prefix,&suffix);split(&nodes,prefix,op.left,&prefix,&middle);if(op.kind==0)reverse_node(&nodes,middle);else{answers[answer_count]=sm(&nodes,middle);answer_count+=1;}root=merge(&nodes,merge(&nodes,prefix,middle),suffix);}
    usz bytes=8*query_count;if(output==null||capacity<bytes)return -2;for(usz i=0;i<query_count;i+=1)put64(output,8*i,answers[i]);return (long)bytes;
}
