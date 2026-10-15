module treap_unique_key_set;

const int MAX_OPS = 128;
const int MAX_NODES = MAX_OPS + 1;
struct Node { int key; long priority; int left; int right; }
fn long priority_for(int key) { return (((long)key + 1000000) * 1103515245 + 12345) % 2147483648; }
fn int contains(Node* nodes, int root, int key) {
    if (root == 0) return 0;
    if (key == nodes[root].key) return 1;
    return contains(nodes, key < nodes[root].key ? nodes[root].left : nodes[root].right, key);
}
fn int rotate_right(Node* nodes, int root) { int pivot=nodes[root].left;nodes[root].left=nodes[pivot].right;nodes[pivot].right=root;return pivot; }
fn int rotate_left(Node* nodes, int root) { int pivot=nodes[root].right;nodes[root].right=nodes[pivot].left;nodes[pivot].left=root;return pivot; }
fn int insert_node(Node* nodes, int* next, int root, int key) {
    if (root == 0) { int id=*next;*next+=1;nodes[id]={key,priority_for(key),0,0};return id; }
    if (key == nodes[root].key) return root;
    if (key < nodes[root].key) { nodes[root].left=insert_node(nodes,next,nodes[root].left,key);if(nodes[nodes[root].left].priority>nodes[root].priority)root=rotate_right(nodes,root); }
    else { nodes[root].right=insert_node(nodes,next,nodes[root].right,key);if(nodes[nodes[root].right].priority>nodes[root].priority)root=rotate_left(nodes,root); }
    return root;
}
fn int merge(Node* nodes, int left, int right) { if(left==0)return right;if(right==0)return left;if(nodes[left].priority>nodes[right].priority){nodes[left].right=merge(nodes,nodes[left].right,right);return left;}nodes[right].left=merge(nodes,left,nodes[right].left);return right; }
fn int erase_node(Node* nodes, int root, int key) { if(key<nodes[root].key)nodes[root].left=erase_node(nodes,nodes[root].left,key);else if(key>nodes[root].key)nodes[root].right=erase_node(nodes,nodes[root].right,key);else return merge(nodes,nodes[root].left,nodes[root].right);return root; }
fn void put_i64(char* output, usz offset, long value) { ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b)); }

fn long treap_unique_key_set(long* input, usz length, char* output, usz capacity) @export("treap_unique_key_set") {
    if(input==null||length<1||input[0]<0||input[0]>MAX_OPS||length!=1+2*(usz)input[0])return -1;
    usz ops=(usz)input[0];for(usz i=0;i<ops;i++){long op=input[1+2*i],key=input[2+2*i];if((op!=0&&op!=1)||key< -1000000||key>1000000)return -1;}
    Node[MAX_NODES] nodes;int next=1,root=0;
    for(usz i=0;i<ops;i++){int op=(int)input[1+2*i],key=(int)input[2+2*i];int present=contains(&nodes[0],root,key);if((op==0&&present!=0)||(op==1&&present==0))return -1;root=op==0?insert_node(&nodes[0],&next,root,key):erase_node(&nodes[0],root,key);}
    int[MAX_OPS] stack;long[MAX_OPS] sorted;int top=0,current=root;usz count=0;
    while(current!=0||top>0){while(current!=0){stack[top++]=current;current=nodes[current].left;}current=stack[--top];sorted[count++]=nodes[current].key;current=nodes[current].right;}
    usz required=count*8;if(output==null||capacity<required)return -2;for(usz i=0;i<count;i++)put_i64(output,8*i,sorted[i]);return (long)count;
}
