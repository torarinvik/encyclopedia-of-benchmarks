/* Return the Ruby BFS seen/visited sets and ordered parent/distance maps. */
#include <stddef.h>
#include <stdint.h>
static void put_i64(uint8_t *out,size_t word,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[word*8+b]=(uint8_t)(bits>>(8*b));}
int64_t bfs_result_tree(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<3)return -1;int64_t nv=in[0],mv=in[1],sv=in[2];if(nv<1||nv>32||mv<0||mv>126||sv<0||sv>=nv||len!=(size_t)(3+2*mv))return -1;
 int n=(int)nv,m=(int)mv,start=(int)sv,adj[32][126],degree[32]={0};
 for(int e=0;e<m;e++){int64_t a=in[3+2*e],b=in[4+2*e];if(a<0||a>=n||b<0||b>=n)return -1;adj[a][degree[a]++]=(int)b;}
 int seen[32]={0},queue[32],order[32],parent[32],distance[32],head=0,tail=0,count=0;for(int i=0;i<n;i++){parent[i]=-1;distance[i]=-1;}
 seen[start]=1;parent[start]=-1;distance[start]=0;queue[tail++]=start;
 while(head<tail){int v=queue[head++];order[count++]=v;for(int j=0;j<degree[v];j++){int w=adj[v][j];if(!seen[w]){seen[w]=1;parent[w]=v;distance[w]=distance[v]+1;queue[tail++]=w;}}}
 size_t words=4+6*(size_t)count;if(!out||cap<words*8)return -2;size_t k=0;put_i64(out,k++ ,count);for(int i=0;i<count;i++)put_i64(out,k++,order[i]);put_i64(out,k++,count);for(int i=0;i<count;i++)put_i64(out,k++,order[i]);put_i64(out,k++,count);for(int i=0;i<count;i++){put_i64(out,k++,order[i]);put_i64(out,k++,parent[order[i]]);}put_i64(out,k++,count);for(int i=0;i<count;i++){put_i64(out,k++,order[i]);put_i64(out,k++,distance[order[i]]);}return (int64_t)(words*8);
}
