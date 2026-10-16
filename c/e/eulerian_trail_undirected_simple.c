#include <stddef.h>
#include <stdint.h>
#define MAX_V 10
#define MAX_E 45
static void dfs(int u,int neighbors[MAX_V][MAX_E],int degree[MAX_V],uint8_t seen[MAX_V][MAX_V],int path[MAX_E+1],int *count){path[(*count)++]=u;for(int i=0;i<degree[u];++i){int v=neighbors[u][i];if(!seen[u][v]){seen[u][v]=seen[v][u]=1;dfs(v,neighbors,degree,seen,path,count);}}}
static void put_i64(uint8_t*out,size_t offset,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[offset+b]=(uint8_t)(bits>>(8*b));}
int64_t eulerian_trail_undirected_simple(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<2||input[0]<2||input[0]>MAX_V||input[1]<0||input[1]>MAX_E)return -1;int n=(int)input[0],m=(int)input[1];if(length!=2+2*(size_t)m)return -1;
 int neighbors[MAX_V][MAX_E],degree[MAX_V]={0},edge_count=0;uint8_t adjacent[MAX_V][MAX_V]={0};
 for(int i=0;i<m;++i){int64_t au=input[2+2*i],av=input[3+2*i];if(au<0||au>=n||av<0||av>=n||au==av)return -1;int u=(int)au,v=(int)av;if(adjacent[u][v])return -1;adjacent[u][v]=adjacent[v][u]=1;neighbors[u][degree[u]++]=v;neighbors[v][degree[v]++]=u;edge_count++;}
 int odd_count=0,start=1;for(int v=0;v<n;++v)if(degree[v]&1){odd_count++;start=v;}if(odd_count!=0&&odd_count!=2)return -1;int status=odd_count==0?1:2;if(status==1)start=1;
 if(edge_count>0){uint8_t reached[MAX_V]={0};int stack[MAX_V],top=0;if(status==1&&degree[1]==0)return -1;stack[top++]=start;reached[start]=1;while(top){int u=stack[--top];for(int i=0;i<degree[u];++i){int v=neighbors[u][i];if(!reached[v]){reached[v]=1;stack[top++]=v;}}}for(int v=0;v<n;++v)if(degree[v]>0&&!reached[v])return -1;}
 uint8_t seen[MAX_V][MAX_V]={0};int path[MAX_E+1],path_count=0;dfs(start,neighbors,degree,seen,path,&path_count);if(path_count!=m+1)return -1;
 size_t bytes=(2+(size_t)path_count)*8;if(!output||capacity<bytes)return -2;put_i64(output,0,status);put_i64(output,8,path_count);for(int i=0;i<path_count;++i)put_i64(output,(2+(size_t)i)*8,path[i]);return (int64_t)bytes;
}
