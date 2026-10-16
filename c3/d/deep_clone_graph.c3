module deep_clone_graph;
fn long mix(long h, ulong x) { for(int b=0;b<8;b++){h=(long)(((ulong)h ^ (x & 255))*1099511628211);x>>=8;}return h; }
fn long deep_clone_graph(long* a, usz len) @export("deep_clone_graph") {
 if(a==null||len<4||len>34)return -1;
 long n=a[0]; long root=a[1]; if(n<1||n>16||root<0||root>=n||len!=2+2*(usz)n)return -1;
 long[16] labels; ulong[16] masks; ulong[16] cm; bool[16] seen; long[256] stack; int top=0; int count=0;
 for(int i=0;i<(int)n;i++){if(a[2+i]<-2147483648||a[2+i]>2147483647||a[2+n+i]<0||((ulong)a[2+n+i]>>n)!=0)return -1;labels[i]=a[2+i];masks[i]=(ulong)a[2+n+i];}
 for(int i=0;i<(int)n;i++)for(int j=0;j<(int)n;j++)if(((masks[i]>>j)&1)!=((masks[j]>>i)&1))return -1;
 stack[top++]=root;while(top>0){int u=(int)stack[--top];if(seen[u])continue;seen[u]=true;count++;cm[u]=masks[u];for(int v=0;v<(int)n;v++)if(((masks[u]>>v)&1)!=0&&!seen[v])stack[top++]=v;}
 long h=mix((long)14695981039346656037,(ulong)count);h=mix(h,(ulong)root);for(int i=0;i<(int)n;i++)if(seen[i]){h=mix(h,(ulong)labels[i]);h=mix(h,cm[i]);}return h;
}
