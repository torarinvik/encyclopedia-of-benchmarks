#include <stddef.h>
#include <stdint.h>
#define MAX_NODE_COUNT 100
static int valid_tree(const int64_t *nodes,size_t n,int64_t node,uint8_t *seen,size_t *count){
 if(node==-1)return 1; if(node<0||(uint64_t)node>=n)return 0; size_t i=(size_t)node; if(seen[i])return 0; seen[i]=1;(*count)++;
 int64_t v=nodes[3*i],l=nodes[3*i+1],r=nodes[3*i+2]; if(v<INT32_MIN||v>INT32_MAX||l< -1||r< -1||(l>=0&&(uint64_t)l>=n)||(r>=0&&(uint64_t)r>=n))return 0;
 return valid_tree(nodes,n,l,seen,count)&&valid_tree(nodes,n,r,seen,count);
}
static int leaf(const int64_t*n,size_t i){return n[3*i+1]==-1&&n[3*i+2]==-1;}
static void leaves(const int64_t*n,int64_t node,int64_t*out,size_t*used){if(node==-1)return;size_t i=(size_t)node;if(leaf(n,i)){out[(*used)++]=n[3*i];return;}leaves(n,n[3*i+1],out,used);leaves(n,n[3*i+2],out,used);}
int64_t boundary_traversal(const int64_t*nodes,size_t n,int64_t root,int64_t*out,size_t cap){
 if(n>MAX_NODE_COUNT||cap<n)return -1; if(n==0)return root==-1?0:-1; if(!nodes||!out||root<0||(uint64_t)root>=n)return -1;
 uint8_t seen[MAX_NODE_COUNT]={0};size_t reached=0;if(!valid_tree(nodes,n,root,seen,&reached)||reached!=n)return -1;
 size_t used=0,ri=(size_t)root; if(!leaf(nodes,ri))out[used++]=nodes[3*ri];
 int64_t cur=nodes[3*ri+1];if(cur==-1&&nodes[3*ri+2]!=-1)cur=nodes[3*ri+2];
 while(cur!=-1){size_t i=(size_t)cur;if(!leaf(nodes,i))out[used++]=nodes[3*i];if(nodes[3*i+1]!=-1)cur=nodes[3*i+1];else cur=nodes[3*i+2];}
 leaves(nodes,root,out,&used);
 if(nodes[3*ri+2]!=-1&&nodes[3*ri+1]==-1)return (int64_t)used;
 int64_t right[MAX_NODE_COUNT];size_t rn=0;cur=nodes[3*ri+2];
 while(cur!=-1){size_t i=(size_t)cur;if(!leaf(nodes,i))right[rn++]=nodes[3*i];if(nodes[3*i+2]!=-1)cur=nodes[3*i+2];else cur=nodes[3*i+1];}
 while(rn>0)out[used++]=right[--rn];return (int64_t)used;
}
