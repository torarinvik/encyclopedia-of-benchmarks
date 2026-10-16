module gomory_hu_tree;
const usz N = 8;
fn void maxflow(long[64]* cap, usz n, usz source, usz sink, long* value, bool[8]* reach) {
    long[64] residual;
    for (usz i=0;i<n*n;i++) residual[i]=(*cap)[i];
    int[8] parent; usz[8] queue; long total=0;
    while (true) {
        for(usz i=0;i<n;i++) parent[i]=-1; parent[source]=(int)source;
        usz head=0; usz tail=1; queue[0]=source;
        while(head<tail && parent[sink]<0){usz u=queue[head];head++;for(usz v=0;v<n;v++)if(residual[u*n+v]>0&&parent[v]<0){parent[v]=(int)u;if(v==sink)break;queue[tail]=v;tail++;}}
        if(parent[sink]<0)break;
        long amount=2147483647;usz z=sink;
        while(z!=source){usz u=(usz)parent[z];if(residual[u*n+z]<amount)amount=residual[u*n+z];z=u;}
        z=sink;while(z!=source){usz u=(usz)parent[z];residual[u*n+z]-=amount;residual[z*n+u]+=amount;z=u;}total+=amount;
    }
    for(usz i=0;i<n;i++)(*reach)[i]=false;usz head=0;usz tail=1;queue[0]=source;(*reach)[source]=true;
    while(head<tail){usz u=queue[head];head++;for(usz v=0;v<n;v++)if(!(*reach)[v]&&residual[u*n+v]>0){(*reach)[v]=true;queue[tail]=v;tail++;}}
    *value=total;
}
fn long gomory_hu_tree(long* a, usz length) @export("gomory_hu_tree") {
    if(a==null||length<2||length>65)return -1;long n0=a[0];if(n0<1||n0>8||length!=1+(usz)(n0*n0))return -1;usz n=(usz)n0;
    long[64] cap;for(usz i=0;i<n*n;i++){if(a[1+i]<0||a[1+i]>1000)return -1;cap[i]=a[1+i];}
    for(usz i=0;i<n;i++)for(usz j=0;j<n;j++)if(cap[i*n+j]!=(i==j?0:cap[j*n+i]))return -1;
    usz[8] parent;long[8] weight;for(usz i=0;i<n;i++){parent[i]=0;weight[i]=0;}
    for(usz s=1;s<n;s++){usz t=parent[s];bool[8] reach;long f=0;maxflow(&cap,n,s,t,&f,&reach);weight[s]=f;
        for(usz v=0;v<n;v++)if(v!=s&&parent[v]==t&&reach[v])parent[v]=s;
        if(t!=0&&reach[parent[t]]){parent[s]=parent[t];parent[t]=s;weight[s]=weight[t];weight[t]=f;}
    }
    long[64] pair;for(usz i=0;i<n*n;i++)pair[i]=0;
    for(usz source=0;source<n;source++){int[8] prev;usz[8] q;for(usz i=0;i<n;i++)prev[i]=-2;usz head=0;usz tail=1;q[0]=source;prev[source]=-1;
        while(head<tail){usz u=q[head];head++;for(usz v=0;v<n;v++)if(v!=u&&((v>0&&parent[v]==u)||(u>0&&parent[u]==v))&&prev[v]==-2){prev[v]=(int)u;q[tail]=v;tail++;}}
        for(usz target=0;target<n;target++)if(target!=source){usz x=target;long minimum=2147483647;while(x!=source){usz p=(usz)prev[x];usz edge=(x>0&&parent[x]==p)?x:p;if(weight[edge]<minimum)minimum=weight[edge];x=p;}pair[source*n+target]=minimum;}
    }
    ulong h=14695981039346656037;for(usz i=0;i<n*n;i++){ulong bits=(ulong)pair[i];for(usz k=0;k<8;k++){h=(h^(bits&255))*1099511628211;bits>>=8;}}return (long)h;
}
