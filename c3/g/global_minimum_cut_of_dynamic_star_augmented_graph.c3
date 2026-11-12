module global_minimum_cut_of_dynamic_star_augmented_graph;
const usz MAX_N=16,MAX_M=64,MAX_Q=32,MAX_V=17,MAX_INPUT=276,MAX_OUTPUT=256;
const long MAX_W=1000000;
fn void store_le(uint8 *out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[at+b]=(uint8)(bits&255ul);bits>>=8;}}
fn long stoer_wagner(usz n,long *spokes,usz m,long *eu,long *ev,long *ew){
    usz vc=n+1;long[MAX_V][MAX_V] w=zeroed;for(usz e=0;e<m;e++){usz u=(usz)eu[e],v=(usz)ev[e];w[u][v]+=ew[e];w[v][u]+=ew[e];}for(usz u=0;u<n;u++){w[u][n]+=spokes[u];w[n][u]+=spokes[u];}
    usz[MAX_V] active;usz count=vc;for(usz i=0;i<vc;i++)active[i]=i;long best=0x7FFFFFFFFFFFFFFF;
    while(count>1){bool[MAX_V] used=zeroed;long[MAX_V] connection=zeroed;int previous=-1;
        for(usz step=0;step<count;step++){int selected=-1;for(usz z=0;z<count;z++){int u=(int)active[z];if(!used[(usz)u]&&(selected<0||connection[(usz)u]>connection[(usz)selected]||(connection[(usz)u]==connection[(usz)selected]&&u<selected)))selected=u;}
            if(step+1==count){if(connection[(usz)selected]<best)best=connection[(usz)selected];for(usz z=0;z<count;z++){int u=(int)active[z];if(u!=selected&&u!=previous){w[(usz)previous][(usz)u]+=w[(usz)selected][(usz)u];w[(usz)u][(usz)previous]=w[(usz)previous][(usz)u];}}usz pos=0;while((int)active[pos]!=selected)pos++;for(usz z=pos+1;z<count;z++)active[z-1]=active[z];count--;break;}
            used[(usz)selected]=true;previous=selected;for(usz z=0;z<count;z++){usz u=active[z];if(!used[u])connection[u]+=w[(usz)selected][u];}
        }
    }return best;
}
fn long global_minimum_cut_of_dynamic_star_augmented_graph(long *input,usz length,uint8 *output,usz capacity) @export("global_minimum_cut_of_dynamic_star_augmented_graph"){
    if(input==null||length<3||length>MAX_INPUT)return -1;long n0=input[0],m0=input[1],q0=input[2];if(n0<1||n0>16||m0<0||m0>64||m0>n0*(n0-1)/2||q0<1||q0>32)return -1;usz n=(usz)n0,m=(usz)m0,q=(usz)q0;if(length!=3+n+3*m+2*q)return -1;usz pos=3;
    long[MAX_N] spokes;for(usz i=0;i<n;i++){spokes[i]=input[pos++];if(spokes[i]<0||spokes[i]>MAX_W)return -1;}long[MAX_M] eu,ev,ew;bool[MAX_N][MAX_N] seen=zeroed;
    for(usz e=0;e<m;e++){long u=input[pos++],v=input[pos++],weight=input[pos++];if(u<0||u>=n0||v<0||v>=n0||u==v||weight<0||weight>MAX_W)return -1;usz a=(usz)(u<v?u:v),b=(usz)(u<v?v:u);if(seen[a][b])return -1;seen[a][b]=true;eu[e]=u;ev[e]=v;ew[e]=weight;}
    long[MAX_Q] ux,uy;for(usz i=0;i<q;i++){ux[i]=input[pos++];uy[i]=input[pos++];if(ux[i]<0||ux[i]>=n0||uy[i]<0||uy[i]>MAX_W)return -1;}usz bytes=8*q;if(bytes>MAX_OUTPUT)return -1;if(output==null||capacity<bytes)return -2;
    long[MAX_Q] answers;for(usz i=0;i<q;i++){spokes[(usz)ux[i]]=uy[i];answers[i]=stoer_wagner(n,&spokes,m,&eu,&ev,&ew);}for(usz i=0;i<q;i++)store_le(output,8*i,answers[i]);return (long)bytes;
}
