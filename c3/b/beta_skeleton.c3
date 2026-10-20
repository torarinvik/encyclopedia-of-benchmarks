module beta_skeleton;
// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
fn long beta_skeleton(long* input,usz length,uint8* output,usz capacity) @export("beta_skeleton") {
    if(input==null||length<3||length>65)return -1;long n0=input[0];if(n0<1||n0>32||length!=1+2*(usz)n0)return -1;int n=(int)n0;long[32] x,y;
    for(int i=0;i<n;i++){x[i]=input[1+2*i];y[i]=input[2+2*i];if(x[i]<-1000||x[i]>1000||y[i]<-1000||y[i]>1000)return -1;for(int j=0;j<i;j++)if(x[i]==x[j]&&y[i]==y[j])return -1;}
    uint8[992] edges;usz count=0;
    for(int i=0;i<n;i++)for(int j=i+1;j<n;j++){long dx=x[i]-x[j],dy=y[i]-y[j],d2=dx*dx+dy*dy;bool blocked=false;
        for(int k=0;k<n;k++)if(k!=i&&k!=j){long aix=x[k]-x[i],aiy=y[k]-y[i],ajx=x[k]-x[j],ajy=y[k]-y[j];if(aix*aix+aiy*aiy<d2&&ajx*ajx+ajy*ajy<d2){blocked=true;break;}}
        if(!blocked){edges[count++]=(uint8)i;edges[count++]=(uint8)j;}
    }
    if(output==null||capacity<count)return -2;for(usz i=0;i<count;i++)output[i]=edges[i];return (long)count;
}
