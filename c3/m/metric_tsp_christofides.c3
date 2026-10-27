module metric_tsp_christofides;
const usz N=8; const usz MASKS=256;
fn void put64(char* o,usz p,long x){ulong b=(ulong)x;for(usz i=0;i<8;i+=1){o[p+i]=(char)(b&255);b>>=8;}}
long metric_tsp_christofides(long* input,usz length,char* output,usz capacity) @export("metric_tsp_christofides") {
 if(input==null||length<2||length>65)return -1;long n0=input[0];if(n0<1||n0>(long)N||length!=1+(usz)n0*(usz)n0)return -1;usz n=(usz)n0;
 long[N][N] d=zeroed;for(usz i=0;i<n;i+=1)for(usz j=0;j<n;j+=1){long w=input[1+i*n+j];if(w<0||w>10000||(i==j&&w!=0))return -1;d[i][j]=w;}
 for(usz i=0;i<n;i+=1)for(usz j=0;j<n;j+=1){if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<n;k+=1)if(d[i][j]>d[i][k]+d[k][j])return -1;}
 usz bytes=8*(n+2);if(output==null||capacity<bytes)return -2;
 bool[N][N] used=zeroed,tree=zeroed;usz[N] parent=zeroed;for(usz i=0;i<n;i+=1)parent[i]=i;usz accepted=0;
 while(accepted+1<n){usz bu=0,bv=0;long bw=9223372036854775807;for(usz u=0;u<n;u+=1)for(usz v=u+1;v<n;v+=1)if(!used[u][v]&&(d[u][v]<bw||(d[u][v]==bw&&(u<bu||(u==bu&&v<bv))))){bu=u;bv=v;bw=d[u][v];}used[bu][bv]=true;usz a=bu,b=bv;while(parent[a]!=a)a=parent[a];while(parent[b]!=b)b=parent[b];if(a!=b){parent[b]=a;tree[bu][bv]=true;tree[bv][bu]=true;accepted+=1;}}
 usz[N] odd=zeroed;usz on=0;for(usz i=0;i<n;i+=1){usz deg=0;for(usz j=0;j<n;j+=1)if(tree[i][j])deg+=1;if(deg%2==1){odd[on]=i;on+=1;}}
 usz full=(1<<on)-1;long[MASKS] dp=zeroed;usz[MASKS] pick=zeroed;for(usz m=0;m<MASKS;m+=1){dp[m]=9223372036854775807/4;pick[m]=N;}dp[0]=0;
 for(usz mask=1;mask<=full;mask+=1){usz i=0;while((mask&(1<<i))==0)i+=1;usz rest=mask^(1<<i);for(usz j=i+1;j<on;j+=1)if(rest&(1<<j)){usz tail=rest^(1<<j);long val=dp[tail]+d[odd[i]][odd[j]];if(val<dp[mask]){dp[mask]=val;pick[mask]=j;}}}
 usz[N][N] multi=zeroed;for(usz i=0;i<n;i+=1)for(usz j=0;j<n;j+=1)if(tree[i][j])multi[i][j]=1;usz mask=full;
 while(mask!=0){usz i=0;while((mask&(1<<i))==0)i+=1;usz j=pick[mask],u=odd[i],v=odd[j];multi[u][v]+=1;multi[v][u]+=1;mask^=(1<<i)|(1<<j);}
 usz[32] stack=zeroed,rev=zeroed;usz top=1,rc=0;stack[0]=0;while(top>0){usz v=stack[top-1];long w=-1;for(usz x=0;x<n;x+=1)if(multi[v][x]>0){w=(long)x;break;}if(w<0){top-=1;rev[rc]=stack[top];rc+=1;}else{multi[v][(usz)w]-=1;multi[(usz)w][v]-=1;stack[top]=(usz)w;top+=1;}}
 bool[N] seen=zeroed;usz[N] order=zeroed;usz cnt=0;while(rc>0){rc-=1;usz v=rev[rc];if(!seen[v]){seen[v]=true;order[cnt]=v;cnt+=1;}}
 long cost=0;for(usz i=0;i+1<n;i+=1)cost+=d[order[i]][order[i+1]];cost+=d[order[n-1]][0];put64(output,0,cost);for(usz i=0;i<n;i+=1)put64(output,8*(i+1),(long)order[i]);put64(output,8*(n+1),0);return (long)bytes;
}
