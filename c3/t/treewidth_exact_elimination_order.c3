module treewidth_exact_elimination_order;
const int N=8;const int MAX_EDGES=28;const int MAX_INPUT=58;const int MAX_OUTPUT=72;
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;}}
fn long treewidth_exact_elimination_order(long* v,usz length,char* output,usz capacity) @export("treewidth_exact_elimination_order") {
 if(v==null||length<2||length>MAX_INPUT||v[0]<1||v[0]>N||v[1]<0||v[1]>MAX_EDGES)return -1;int n=(int)v[0],m=(int)v[1];if(m>n*(n-1)/2||length!=(usz)(2+2*m))return -1;
 bool[N*N] base={};for(int e=0;e<m;e++){long a0=v[2+2*e],b0=v[3+2*e];if(a0<0||b0<0||a0>=n||b0>=n||a0>=b0)return -1;int a=(int)a0,b=(int)b0;if(base[a*N+b])return -1;base[a*N+b]=true;base[b*N+a]=true;}
 int[N] perm={};int[N] best_order={};for(int i=0;i<n;i++)perm[i]=i;int best_width=N+1;
 for(;;){bool[N*N] adjacent={};bool[N] active={};for(int i=0;i<N*N;i++)adjacent[i]=base[i];for(int i=0;i<n;i++)active[i]=true;int width=0;
  for(int step=0;step<n;step++){int vertex=perm[step],neighbors[N],count=0;for(int other=0;other<n;other++)if(active[other]&&adjacent[vertex*N+other]){neighbors[count]=other;count++;}if(count>width)width=count;for(int i=0;i<count;i++)for(int j=i+1;j<count;j++){int a=neighbors[i],b=neighbors[j];adjacent[a*N+b]=true;adjacent[b*N+a]=true;}active[vertex]=false;}
  if(width<best_width){best_width=width;for(int i=0;i<n;i++)best_order[i]=perm[i];}int pivot=n-2;while(pivot>=0&&perm[pivot]>=perm[pivot+1])pivot--;if(pivot<0)break;int successor=n-1;while(perm[successor]<=perm[pivot])successor--;int temp=perm[pivot];perm[pivot]=perm[successor];perm[successor]=temp;int left=pivot+1,right=n-1;while(left<right){temp=perm[left];perm[left]=perm[right];perm[right]=temp;left++;right--;}}
 usz bytes=8*(usz)(n+1);if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged={};put_i64(staged,0,best_width);for(int i=0;i<n;i++)put_i64(staged,8*(usz)(i+1),best_order[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
