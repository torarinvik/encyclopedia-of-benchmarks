#include <stddef.h>
#include <stdint.h>
#define MAX_N 1024
int64_t binary_tree_is_full(const int64_t *input, size_t length) {
    if (!input || length < 2 || input[0] < 1 || input[0] > MAX_N) return -1;
    int n=(int)input[0]; int64_t root=input[1];
    if (root<0 || root>=n || length!=2+2*(size_t)n) return -1;
    int left[MAX_N],right[MAX_N],parents[MAX_N]={0},stack[MAX_N]; uint8_t seen[MAX_N]={0};
    int full=1;
    for(int i=0;i<n;i++){
        int64_t l=input[2+2*i],r=input[3+2*i];
        if(l < -1 || l>=n || r < -1 || r>=n || l==i || r==i) return -1;
        left[i]=(int)l;right[i]=(int)r;
        if(l>=0) parents[l]++; if(r>=0) parents[r]++;
        if((l<0)!=(r<0)) full=0;
    }
    if(parents[root]!=0) return -1;
    for(int i=0;i<n;i++) if(i!=root && parents[i]!=1) return -1;
    int top=0,visited=0;stack[top++]=(int)root;
    while(top){int node=stack[--top];if(seen[node])return -1;seen[node]=1;visited++;if(left[node]>=0)stack[top++]=left[node];if(right[node]>=0)stack[top++]=right[node];}
    if(visited!=n) return -1;
    return full;
}
