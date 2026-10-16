module dbscan;
import libc;

fn long dbscan(long* input, usz length, char* output, usz capacity) @export("dbscan") {
    if (input == null || length < 5 || length > 67) return -1;
    long n0=input[0]; long eps=input[1]; long minimum=input[2];
    if(n0<1||n0>32||eps<1||eps>2000000||minimum<1||minimum>n0||length != 3 + 2*(usz)n0) return -1;
    usz n=(usz)n0; long[32] x = {}; long[32] y = {}; long[32] labels = {}; bool[32] expanded = {};
    for(usz i=0;i<n;i++){x[i]=input[3+2*i];y[i]=input[4+2*i];labels[i]=-1;if(x[i]<-1000000||x[i]>1000000||y[i]<-1000000||y[i]>1000000)return -1;}
    for(usz i=0;i<n;i++)for(usz j=0;j<i;j++)if(x[i]==x[j]&&y[i]==y[j])return -1;
    if(output==null||capacity<n)return -2;
    long e2=eps*eps; long next=0;
    for(usz i=0;i<n;i++){
        if(labels[i]>=0)continue;usz count=0;
        for(usz j=0;j<n;j++){long dx=x[i]-x[j]; long dy=y[i]-y[j];if(dx*dx+dy*dy<=e2)count++;}
        if(count<(usz)minimum)continue;long cluster=next++;labels[i]=cluster;
        usz[32] queue = {}; bool[32] queued = {}; usz head=0; usz tail=0;
        for(usz j=0;j<n;j++){long dx=x[i]-x[j]; long dy=y[i]-y[j];if(dx*dx+dy*dy<=e2){queue[tail++]=j;queued[j]=true;}}
        while(head<tail){usz q=queue[head++];if(labels[q]>=0&&labels[q]!=cluster)continue;labels[q]=cluster;if(expanded[q])continue;expanded[q]=true;usz nc=0;
            for(usz j=0;j<n;j++){long dx=x[q]-x[j]; long dy=y[q]-y[j];if(dx*dx+dy*dy<=e2)nc++;}
            if(nc>=(usz)minimum)for(usz j=0;j<n;j++){long dx=x[q]-x[j]; long dy=y[q]-y[j];if(dx*dx+dy*dy<=e2&&labels[j]<0&&!queued[j]){queue[tail++]=j;queued[j]=true;}}
        }
    }
    for(usz i=0;i<n;i++)output[i]=(char)(labels[i]<0?0:labels[i]+1);
    return (long)n;
}
