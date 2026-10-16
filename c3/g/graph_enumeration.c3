module graph_enumeration;
fn long graph_enumeration(long* a, usz length) @export("graph_enumeration") {
    if(a==null||length<1)return -1;long n0=a[0];if(n0<0||n0>16||length<1+(usz)n0)return -1;usz n=(usz)n0;
    long[16] labels;long[16] sorted;long[16][32] adj;usz[16] degree;usz off=1+n;
    for(usz i=0;i<n;i++){labels[i]=a[1+i];if(labels[i]<-1000000||labels[i]>1000000)return -1;for(usz j=0;j<i;j++)if(labels[j]==labels[i])return -1;sorted[i]=labels[i];}
    for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++)if(sorted[j]<sorted[i]){long t=sorted[i];sorted[i]=sorted[j];sorted[j]=t;}
    for(usz i=0;i<n;i++){if(off>=length)return -1;long d=a[off++];if(d<0||d>32||off+(usz)d>length)return -1;degree[i]=(usz)d;for(usz j=0;j<degree[i];j++){long x=a[off++];usz k=0;while(k<n&&labels[k]!=x)k++;if(k==n)return -1;adj[i][j]=x;}}
    if(off!=length)return -1;ulong h=14695981039346656037;ulong z=(ulong)(n+1);for(usz b=0;b<8;b++){h=(h^(z&255))*1099511628211;z>>=8;}z=0;for(usz b=0;b<8;b++){h=(h^(z&255))*1099511628211;z>>=8;}
    for(usz s=0;s<n;s++){usz i=0;while(labels[i]!=sorted[s])i++;z=degree[i];for(usz b=0;b<8;b++){h=(h^(z&255))*1099511628211;z>>=8;}for(usz j=0;j<degree[i];j++){usz k=0;while(sorted[k]!=adj[i][j])k++;z=k+1;for(usz b=0;b<8;b++){h=(h^(z&255))*1099511628211;z>>=8;}}}
    return (long)h;
}
