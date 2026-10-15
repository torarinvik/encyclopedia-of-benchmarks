#include <stddef.h>
#include <stdint.h>

#define MAX_INSERTS 64
#define MAX_OPS 128
typedef struct { int64_t key; int left, right, height; } AvlNode;

static int node_height(const AvlNode *nodes, int index) { return index < 0 ? 0 : nodes[index].height; }
static void update_height(AvlNode *nodes, int index) {
    int left=node_height(nodes,nodes[index].left), right=node_height(nodes,nodes[index].right);
    nodes[index].height=1+(left>right?left:right);
}
static int rotate_right(AvlNode *nodes, int root) {
    int pivot=nodes[root].left, middle=nodes[pivot].right;
    nodes[pivot].right=root; nodes[root].left=middle;
    update_height(nodes,root); update_height(nodes,pivot); return pivot;
}
static int rotate_left(AvlNode *nodes, int root) {
    int pivot=nodes[root].right, middle=nodes[pivot].left;
    nodes[pivot].left=root; nodes[root].right=middle;
    update_height(nodes,root); update_height(nodes,pivot); return pivot;
}
static int insert_node(AvlNode *nodes, int root, int64_t key, int *next) {
    if (root < 0) { int index=(*next)++; nodes[index]=(AvlNode){key,-1,-1,1}; return index; }
    if (key < nodes[root].key) nodes[root].left=insert_node(nodes,nodes[root].left,key,next);
    else nodes[root].right=insert_node(nodes,nodes[root].right,key,next);
    update_height(nodes,root);
    int balance=node_height(nodes,nodes[root].left)-node_height(nodes,nodes[root].right);
    if(balance>1){if(key>nodes[nodes[root].left].key)nodes[root].left=rotate_left(nodes,nodes[root].left);return rotate_right(nodes,root);}
    if(balance < -1){if(key<nodes[nodes[root].right].key)nodes[root].right=rotate_right(nodes,nodes[root].right);return rotate_left(nodes,root);}
    return root;
}
static int find_node(const AvlNode *nodes, int root, int64_t key) {
    while(root>=0){if(key==nodes[root].key)return root;root=key<nodes[root].key?nodes[root].left:nodes[root].right;}return -1;
}
static void put_i64(uint8_t *out,size_t offset,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[offset+b]=(uint8_t)(bits>>(8*b));}

int64_t avl_tree_ruby_unique_key_insert_search(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<1)return -1;
    const int64_t op_count=input[0];if(op_count<0||op_count>MAX_OPS||length!=(size_t)(1+2*op_count))return -1;
    int64_t inserted[MAX_INSERTS];size_t insert_count=0,search_count=0;
    for(size_t i=0;i<(size_t)op_count;i++){int64_t op=input[1+2*i],key=input[2+2*i];if((op!=0&&op!=1)||key < -1000000||key>1000000)return -1;
        if(op==0){if(insert_count>=MAX_INSERTS)return -1;for(size_t j=0;j<insert_count;j++)if(inserted[j]==key)return -1;inserted[insert_count++]=key;}else search_count++;}
    AvlNode nodes[MAX_INSERTS];int root=-1,next=0;size_t query_index=0;uint8_t query_results[MAX_OPS];
    for(size_t i=0;i<(size_t)op_count;i++){int64_t op=input[1+2*i],key=input[2+2*i];if(op==0)root=insert_node(nodes,root,key,&next);else query_results[query_index++]=(uint8_t)(find_node(nodes,root,key)>=0);}
    const size_t output_count=2+insert_count+search_count,bytes=output_count*8;
    if(output==NULL||capacity<bytes)return -2;
    put_i64(output,0,(int64_t)insert_count);int stack[MAX_INSERTS],top=0,current=root;size_t out_index=1;
    while(current>=0||top>0){while(current>=0){stack[top++]=current;current=nodes[current].left;}current=stack[--top];put_i64(output,out_index++*8,nodes[current].key);current=nodes[current].right;}
    put_i64(output,out_index++*8,(int64_t)search_count);for(size_t i=0;i<search_count;i++)put_i64(output,out_index++*8,query_results[i]);
    return (int64_t)bytes;
}
