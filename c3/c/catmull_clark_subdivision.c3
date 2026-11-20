module catmull_clark_subdivision;

extern fn double fabs(double value);
extern fn double trunc(double value);

const int MAX_V = 24, MAX_F = 8, MAX_D = 8, MAX_E = 32, MAX_IN = 122, MAX_OUT = 386;
const double MAX_FINITE = 1.7976931348623157e308;

fn int cc_int(double value, int low, int high) {
    if (value != value || fabs(value) > MAX_FINITE || trunc(value) != value || value < (double)low || value > (double)high) return -1;
    return (int)value;
}
fn double cc_mean(double* values, int count) {
    double scale = 0.0;
    for (int i=0; i<count; i+=1) if(fabs(values[i])>scale) scale=fabs(values[i]);
    if(scale==0.0)return 0.0;
    double sum=0.0;for(int i=0;i<count;i+=1)sum+=values[i]/scale;
    return (sum/(double)count)*scale;
}
fn double cc_avg4(double a,double b,double c,double d){
    double scale=fabs(a);if(fabs(b)>scale)scale=fabs(b);if(fabs(c)>scale)scale=fabs(c);if(fabs(d)>scale)scale=fabs(d);
    if(scale==0.0)return 0.0;return ((a/scale+b/scale+c/scale+d/scale)*0.25)*scale;
}

fn long catmull_clark_subdivision(double* input, usz length, double* output, usz capacity)
    @export("catmull_clark_subdivision") {
    if(input==null||length<2||length>MAX_IN)return -1;
    for(usz i=0;i<length;i+=1)if(input[i]!=input[i]||fabs(input[i])>MAX_FINITE)return -1;
    int nv=cc_int(input[0],0,MAX_V),nf=cc_int(input[1],0,MAX_F);if(nv<0||nf<0)return -1;
    if((nv==0||nf==0)&&!(nv==0&&nf==0&&length==2))return -1;
    double[MAX_V] x=zeroed,y=zeroed;int[MAX_F] degree=zeroed;int[MAX_F][MAX_D] face=zeroed;
    usz pos=2;if(pos+(usz)(2*nv)>length)return -1;
    for(int v=0;v<nv;v+=1){x[v]=input[pos];y[v]=input[pos+1];pos+=2;}
    int[MAX_E] eu=zeroed,ev=zeroed,ef0=zeroed,ef1=zeroed,uses=zeroed;int ne=0;
    for(int f=0;f<nf;f+=1){
        if(pos>=length)return -1;degree[f]=cc_int(input[pos],3,MAX_D);pos+=1;
        if(degree[f]<0||pos+(usz)degree[f]>length)return -1;
        for(int i=0;i<degree[f];i+=1){face[f][i]=cc_int(input[pos],0,nv-1);pos+=1;if(face[f][i]<0)return -1;for(int j=0;j<i;j+=1)if(face[f][i]==face[f][j])return -1;}
        for(int i=0;i<degree[f];i+=1){int a=face[f][i],b=face[f][(i+1)%degree[f]],u=a<b?a:b,v=a<b?b:a,found=-1;
            for(int e=0;e<ne;e+=1)if(eu[e]==u&&ev[e]==v){found=e;break;}
            if(found<0){if(ne==MAX_E)return -1;found=ne;ne+=1;eu[found]=u;ev[found]=v;ef0[found]=f;ef1[found]=-1;uses[found]=1;}
            else{if(uses[found]!=1||ef0[found]==f)return -1;uses[found]=2;ef1[found]=f;}
        }
    }
    if(pos!=length)return -1;for(int e=0;e<ne;e+=1)if(uses[e]!=2)return -1;
    for(int v=0;v<nv;v+=1){
        int[MAX_F] la=zeroed,lb=zeroed;int links=0,valence=0;
        for(int e=0;e<ne;e+=1)if(eu[e]==v||ev[e]==v)valence+=1;
        for(int f=0;f<nf;f+=1)for(int i=0;i<degree[f];i+=1)if(face[f][i]==v){int a=face[f][(i+degree[f]-1)%degree[f]],b=face[f][(i+1)%degree[f]],lo=a<b?a:b,hi=a<b?b:a;
            for(int j=0;j<links;j+=1){int oldlo=la[j]<lb[j]?la[j]:lb[j],oldhi=la[j]<lb[j]?lb[j]:la[j];if(lo==oldlo&&hi==oldhi)return -1;}
            la[links]=a;lb[links]=b;links+=1;
        }
        if(valence<3||links!=valence)return -1;
        bool[MAX_V] reached=zeroed;reached[la[0]]=true;bool changed=true;
        while(changed){changed=false;for(int i=0;i<links;i+=1){if(reached[la[i]]&&!reached[lb[i]]){reached[lb[i]]=true;changed=true;}if(reached[lb[i]]&&!reached[la[i]]){reached[la[i]]=true;changed=true;}}}
        int[MAX_V] node_degree=zeroed;for(int i=0;i<links;i+=1){node_degree[la[i]]+=1;node_degree[lb[i]]+=1;}int nodes=0;
        for(int u=0;u<nv;u+=1)if(node_degree[u]!=0){nodes+=1;if(node_degree[u]!=2||!reached[u])return -1;}if(nodes<3)return -1;
    }
    for(int i=1;i<ne;i+=1){int u=eu[i],v=ev[i],a=ef0[i],b=ef1[i],j=i;while(j>0&&(eu[j-1]>u||(eu[j-1]==u&&ev[j-1]>v))){eu[j]=eu[j-1];ev[j]=ev[j-1];ef0[j]=ef0[j-1];ef1[j]=ef1[j-1];j-=1;}eu[j]=u;ev[j]=v;ef0[j]=a;ef1[j]=b;}
    double[MAX_F] fx=zeroed,fy=zeroed;
    for(int f=0;f<nf;f+=1){double[MAX_D] vx=zeroed,vy=zeroed;for(int i=0;i<degree[f];i+=1){vx[i]=x[face[f][i]];vy[i]=y[face[f][i]];}fx[f]=cc_mean(&vx[0],degree[f]);fy[f]=cc_mean(&vy[0],degree[f]);}
    double[MAX_OUT] staged=zeroed;usz out=0;int new_v=nv+ne+nf,new_f=0;for(int f=0;f<nf;f+=1)new_f+=degree[f];staged[out]=(double)new_v;out+=1;staged[out]=(double)new_f;out+=1;
    for(int v=0;v<nv;v+=1){double[MAX_F] fxs=zeroed,fys=zeroed,rx=zeroed,ry=zeroed;int nfi=0,nei=0;
        for(int f=0;f<nf;f+=1){for(int i=0;i<degree[f];i+=1)if(face[f][i]==v){fxs[nfi]=fx[f];fys[nfi]=fy[f];nfi+=1;break;}}
        for(int e=0;e<ne;e+=1)if(eu[e]==v||ev[e]==v){double[2] qx={x[eu[e]],x[ev[e]]},qy={y[eu[e]],y[ev[e]]};rx[nei]=cc_mean(&qx[0],2);ry[nei]=cc_mean(&qy[0],2);nei+=1;}
        double fxa=cc_mean(&fxs[0],nfi),fya=cc_mean(&fys[0],nfi),rxa=cc_mean(&rx[0],nei),rya=cc_mean(&ry[0],nei),sx=fabs(x[v]),sy=fabs(y[v]);
        if(fabs(fxa)>sx)sx=fabs(fxa);if(fabs(rxa)>sx)sx=fabs(rxa);if(fabs(fya)>sy)sy=fabs(fya);if(fabs(rya)>sy)sy=fabs(rya);
        double px=sx==0.0?0.0:((fxa/sx+2.0*rxa/sx+(nei-3)*(x[v]/sx))/nei)*sx;
        double py=sy==0.0?0.0:((fya/sy+2.0*rya/sy+(nei-3)*(y[v]/sy))/nei)*sy;
        staged[out]=px;out+=1;staged[out]=py;out+=1;
    }
    for(int e=0;e<ne;e+=1){staged[out]=cc_avg4(x[eu[e]],x[ev[e]],fx[ef0[e]],fx[ef1[e]]);out+=1;staged[out]=cc_avg4(y[eu[e]],y[ev[e]],fy[ef0[e]],fy[ef1[e]]);out+=1;}
    for(int f=0;f<nf;f+=1){staged[out]=fx[f];out+=1;staged[out]=fy[f];out+=1;}
    for(int f=0;f<nf;f+=1)for(int i=0;i<degree[f];i+=1){int v=face[f][i],n=face[f][(i+1)%degree[f]],p=face[f][(i+degree[f]-1)%degree[f]],en=-1,ep=-1,u1=v<n?v:n,w1=v<n?n:v,u2=p<v?p:v,w2=p<v?v:p;
        for(int e=0;e<ne;e+=1){if(eu[e]==u1&&ev[e]==w1)en=e;if(eu[e]==u2&&ev[e]==w2)ep=e;}
        staged[out]=(double)v;out+=1;staged[out]=(double)(nv+en);out+=1;staged[out]=(double)(nv+ne+f);out+=1;staged[out]=(double)(nv+ep);out+=1;
    }
    if(out>MAX_OUT)return -1;if(output==null||capacity<out)return -2;for(usz i=0;i<out;i+=1)output[i]=staged[i];return (long)out;
}
