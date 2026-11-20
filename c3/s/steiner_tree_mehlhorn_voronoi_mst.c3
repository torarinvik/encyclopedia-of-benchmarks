module steiner_tree_mehlhorn_voronoi_mst;
const int N=8, M=14, MAX_INPUT=54, MAX_OUTPUT=72;
const long INF=4611686018427387903;

fn int root(int[N] parent, int x) { while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];} return x; }
fn bool join(int[N] parent,int[N] rank,int a,int b){int ra=root(parent,a),rb=root(parent,b);if(ra==rb)return false;if(rank[ra]<rank[rb]){int t=ra;ra=rb;rb=t;}parent[rb]=ra;if(rank[ra]==rank[rb])rank[ra]++;return true;}
fn bool before(long aw,int aa,int ab,int al,int ar,int ae,long bw,int ba,int bb,int bl,int br,int be){if(aw!=bw)return aw<bw;if(aa!=ba)return aa<ba;if(ab!=bb)return ab<bb;if(al!=bl)return al<bl;if(ar!=br)return ar<br;return ae<be;}
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[at+b]=(char)(bits&255);bits=bits>>8;}}

fn long steiner_tree_mehlhorn_voronoi_mst(long* input,usz input_length,char* output,usz output_capacity) @export("steiner_tree_mehlhorn_voronoi_mst") {
 if(input==null||input_length<3||input_length>MAX_INPUT)return -1;
 long n0=input[0],m0=input[1],k0=input[2];if(n0<2||n0>N||m0<1||m0>M||k0<2||k0>n0)return -1;
 int n=(int)n0,m=(int)m0,k=(int)k0;if(input_length<(usz)(3+k+3*m))return -1;
 int[N] terminals={0};bool[N] terminal_flag={false};usz at=3;
 for(int i=0;i<k;i++){long t0=input[at++];if(t0<0||t0>=n0||terminal_flag[(int)t0])return -1;terminals[i]=(int)t0;terminal_flag[(int)t0]=true;}
 int[M] eu={0},ev={0},weight={0};bool[N][N] pair_seen={false};
 for(int e=0;e<m;e++){long u0=input[at++],v0=input[at++],w0=input[at++];if(u0<0||u0>=v0||v0>=n0||w0<1||w0>9)return -1;int u=(int)u0,v=(int)v0;if(pair_seen[u][v])return -1;pair_seen[u][v]=true;eu[e]=u;ev[e]=v;weight[e]=(int)w0;}
 if(at!=input_length)return -1;
 bool[N] reached={false};int[N] queue={0};int head=0,tail=0;reached[0]=true;queue[tail++]=0;
 while(head<tail){int u=queue[head++];for(int e=0;e<m;e++){int v=-1;if(eu[e]==u)v=ev[e];else if(ev[e]==u)v=eu[e];if(v>=0&&!reached[v]){reached[v]=true;queue[tail++]=v;}}}
 for(int v=0;v<n;v++)if(!reached[v])return -1;
 long[N] dist={0};int[N] owner={0},pred={0},pred_edge={0};bool[N] settled={false};
 for(int v=0;v<n;v++){dist[v]=INF;owner[v]=n;pred[v]=-1;pred_edge[v]=-1;}for(int i=0;i<k;i++){int t=terminals[i];dist[t]=0;owner[t]=t;}
 for(int step=0;step<n;step++){int u=-1;for(int v=0;v<n;v++)if(!settled[v]&&(u<0||dist[v]<dist[u]||(dist[v]==dist[u]&&(owner[v]<owner[u]||(owner[v]==owner[u]&&v<u))))u=v;if(u<0||dist[u]==INF)break;settled[u]=true;
  for(int e=0;e<m;e++){int v=-1;if(eu[e]==u)v=ev[e];else if(ev[e]==u)v=eu[e];if(v<0)continue;long nd=dist[u]+weight[e];if(nd<dist[v]||(nd==dist[v]&&owner[u]<owner[v])){dist[v]=nd;owner[v]=owner[u];pred[v]=u;pred_edge[v]=e;}else if(nd==dist[v]&&owner[u]==owner[v]&&!settled[v]&&(pred[v]<0||u<pred[v]||(u==pred[v]&&e<pred_edge[v]))){pred[v]=u;pred_edge[v]=e;}}
 }
 long[N][N] best_weight={0};int[N][N] has={0},best_left={0},best_right={0},best_edge={0};
 for(int e=0;e<m;e++){int u=eu[e],v=ev[e],a=owner[u],b=owner[v];if(a==b)continue;int left=u,right=v;if(a>b){int t=a;a=b;b=t;left=v;right=u;}long cw=dist[u]+weight[e]+dist[v];if(!has[a][b]||before(cw,a,b,left,right,e,best_weight[a][b],a,b,best_left[a][b],best_right[a][b],best_edge[a][b])){has[a][b]=1;best_weight[a][b]=cw;best_left[a][b]=left;best_right[a][b]=right;best_edge[a][b]=e;}}
 int cn=0;long[M] cw={0};int[M] ca={0},cb={0},cl={0},cr={0},ce={0};
 for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)if(has[a][b]){cw[cn]=best_weight[a][b];ca[cn]=a;cb[cn]=b;cl[cn]=best_left[a][b];cr[cn]=best_right[a][b];ce[cn]=best_edge[a][b];cn++;}
 for(int i=1;i<cn;i++){long w=cw[i];int a=ca[i],b=cb[i],l=cl[i],r=cr[i],e=ce[i],j=i;while(j>0&&before(w,a,b,l,r,e,cw[j-1],ca[j-1],cb[j-1],cl[j-1],cr[j-1],ce[j-1])){cw[j]=cw[j-1];ca[j]=ca[j-1];cb[j]=cb[j-1];cl[j]=cl[j-1];cr[j]=cr[j-1];ce[j]=ce[j-1];j--;}cw[j]=w;ca[j]=a;cb[j]=b;cl[j]=l;cr[j]=r;ce[j]=e;}
 int[N] parent={0},rank={0},chosen={0};for(int v=0;v<n;v++)parent[v]=v;int chosen_count=0;for(int i=0;i<cn&&chosen_count<k-1;i++)if(join(parent,rank,ca[i],cb[i]))chosen[chosen_count++]=i;if(chosen_count!=k-1)return -1;
 bool[M] used={false};for(int i=0;i<chosen_count;i++){int ix=chosen[i];used[ce[ix]]=true;int x=cl[ix];while(x!=ca[ix]){if(pred_edge[x]<0)return -1;used[pred_edge[x]]=true;x=pred[x];}x=cr[ix];while(x!=cb[ix]){if(pred_edge[x]<0)return -1;used[pred_edge[x]]=true;x=pred[x];}}
 int[M] order={0};int on=0;for(int e=0;e<m;e++)if(used[e])order[on++]=e;for(int i=1;i<on;i++){int e=order[i],j=i;while(j>0&&(weight[e]<weight[order[j-1]]||(weight[e]==weight[order[j-1]]&&e<order[j-1]))){order[j]=order[j-1];j--;}order[j]=e;}
 for(int v=0;v<n;v++)parent[v]=v,rank[v]=0;bool[M] tree={false};for(int i=0;i<on;i++){int e=order[i];if(join(parent,rank,eu[e],ev[e]))tree[e]=true;}int r0=root(parent,terminals[0]);for(int i=1;i<k;i++)if(root(parent,terminals[i])!=r0)return -1;
 int[N] degree={0};for(int e=0;e<m;e++)if(tree[e]){degree[eu[e]]++;degree[ev[e]]++;}bool[N] queued={false};int[N] leaves={0};head=0;tail=0;for(int v=0;v<n;v++)if(!terminal_flag[v]&&degree[v]<=1){leaves[tail++]=v;queued[v]=true;}
 while(head<tail){int u=leaves[head++];if(degree[u]>1)continue;for(int e=0;e<m;e++)if(tree[e]&&(eu[e]==u||ev[e]==u)){tree[e]=false;int v=eu[e]==u?ev[e]:eu[e];degree[u]--;degree[v]--;if(!terminal_flag[v]&&degree[v]<=1&&!queued[v]){leaves[tail++]=v;queued[v]=true;}}}
 int result_count=0;long cost=0;int[M] result={0};for(int e=0;e<m;e++)if(tree[e]){result[result_count++]=e;cost+=weight[e];}if(result_count<=0||result_count>n-1)return -1;
 usz bytes=(usz)(2+result_count)*8;if(output==null||output_capacity<bytes||bytes>MAX_OUTPUT)return -2;put_i64(output,0,cost);put_i64(output,8,result_count);for(int i=0;i<result_count;i++)put_i64(output,16+(usz)i*8,result[i]);return (long)bytes;
}
