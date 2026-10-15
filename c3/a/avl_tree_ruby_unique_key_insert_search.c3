module avl_tree_ruby_unique_key_insert_search;

const usz MAX_NODES = 64;
const usz MAX_OPS = 128;
struct Node { long key; int left; int right; int height; }
fn int height(Node* nodes, int index) { return index < 0 ? 0 : nodes[index].height; }
fn void update(Node* nodes, int index) { int a=height(nodes,nodes[index].left),b=height(nodes,nodes[index].right);nodes[index].height=1+(a>b?a:b); }
fn int rotate_right(Node* nodes,int root){int pivot=nodes[root].left,middle=nodes[pivot].right;nodes[pivot].right=root;nodes[root].left=middle;update(nodes,root);update(nodes,pivot);return pivot;}
fn int rotate_left(Node* nodes,int root){int pivot=nodes[root].right,middle=nodes[pivot].left;nodes[pivot].left=root;nodes[root].right=middle;update(nodes,root);update(nodes,pivot);return pivot;}
fn int insert_node(Node* nodes,int root,long key,int* next){if(root<0){int i=*next;*next=*next+1;nodes[i]={key,-1,-1,1};return i;}if(key<nodes[root].key)nodes[root].left=insert_node(nodes,nodes[root].left,key,next);else nodes[root].right=insert_node(nodes,nodes[root].right,key,next);update(nodes,root);int bf=height(nodes,nodes[root].left)-height(nodes,nodes[root].right);if(bf>1){if(key>nodes[nodes[root].left].key)nodes[root].left=rotate_left(nodes,nodes[root].left);return rotate_right(nodes,root);}if(bf < -1){if(key<nodes[nodes[root].right].key)nodes[root].right=rotate_right(nodes,nodes[root].right);return rotate_left(nodes,root);}return root;}
fn bool contains(Node* nodes,int root,long key){while(root>=0){if(nodes[root].key==key)return true;root=key<nodes[root].key?nodes[root].left:nodes[root].right;}return false;}
fn void put_i64(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(b*8));}

fn long avl_tree_ruby_unique_key_insert_search(long* input,usz length,char* output,usz capacity) @export("avl_tree_ruby_unique_key_insert_search") {
    if(input==null||length<1)return -1;long ops64=input[0];if(ops64<0||ops64>128||length!=(usz)(1+2*ops64))return -1;usz ops=(usz)ops64;
    long[64] inserted;usz inserts=0,searches=0;
    for(usz i=0;i<ops;i++){long op=input[1+2*i],key=input[2+2*i];if((op!=0&&op!=1)||key < -1000000||key>1000000)return -1;if(op==0){if(inserts>=64)return -1;for(usz j=0;j<inserts;j++)if(inserted[j]==key)return -1;inserted[inserts++]=key;}else searches++;}
    Node[64] nodes;for(usz i=0;i<64;i++){nodes[i].left=-1;nodes[i].right=-1;nodes[i].height=0;}
    int root=-1,next=0;long[128] results;usz q=0;
    for(usz i=0;i<ops;i++){long op=input[1+2*i],key=input[2+2*i];if(op==0)root=insert_node(&nodes,root,key,&next);else results[q++]=contains(&nodes,root,key)?1:0;}
    usz bytes=(2+inserts+searches)*8;if(output==null||capacity<bytes)return -2;put_i64(output,0,(long)inserts);int[64] stack;usz top=0;int current=root;usz out=1;
    while(current>=0||top>0){while(current>=0){stack[top++]=current;current=nodes[current].left;}current=stack[--top];put_i64(output,out++*8,nodes[current].key);current=nodes[current].right;}
    put_i64(output,out++*8,(long)searches);for(usz i=0;i<searches;i++)put_i64(output,out++*8,results[i]);return (long)bytes;
}
