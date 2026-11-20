module wulff_nilsen_distance_refinement;

const long SCALE = 86093442;
const long INF = 1152921504606846976;
const int MAX_N = 8;

fn int even_index(int x, long threshold, int* nearest, long* distance) {
    return distance[x*MAX_N+nearest[2*MAX_N+x]] <= threshold ? 2 : 0;
}

fn bool refine_further(int u, int v, int iu, int* nearest, bool* bunch, long* distance) {
    if (iu < 2) return false;
    int j = 0;
    return bunch[v*MAX_N+nearest[j*MAX_N+u]] ||
        bunch[u*MAX_N+nearest[(j+1)*MAX_N+v]] ||
        bunch[v*MAX_N+nearest[iu*MAX_N+u]] ||
        bunch[u*MAX_N+nearest[(iu+1)*MAX_N+v]];
}

fn long wulff_nilsen_distance_refinement(long* input, usz length) @export("wulff_nilsen_distance_refinement") {
    if (input == null || length < 8 || length > 93) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 2 || n0 > MAX_N || m0 < 0 || m0 > 28) return -1;
    int n = (int)n0, m = (int)m0;
    if (length != (usz)(8 + 3*m)) return -1;
    long full = (1 << n) - 1;
    long[3] masks;
    for (int i=0; i<3; i++) { masks[i]=input[2+i]; if(masks[i]<=0||(masks[i]&~full)!=0)return -1; }
    if ((masks[1]&~masks[0])!=0||(masks[2]&~masks[1])!=0)return -1;

    long[64] distance;
    for(int u=0;u<n;u++)for(int v=0;v<n;v++)distance[u*MAX_N+v]=u==v?0:INF;
    int prev_u=-1,prev_v=-1;
    for(int e=0;e<m;e++){
        usz at=(usz)(5+3*e);long u0=input[at],v0=input[at+1],w=input[at+2];
        if(u0<0||u0>=n||v0<=u0||v0>=n||w<SCALE||w>100*SCALE||w%SCALE!=0)return -1;
        int u=(int)u0,v=(int)v0;if(u<prev_u||(u==prev_u&&v<=prev_v))return -1;prev_u=u;prev_v=v;
        distance[u*MAX_N+v]=w;distance[v*MAX_N+u]=w;
    }
    usz q=(usz)(5+3*m);long u0=input[q],v0=input[q+1],estimate=input[q+2];
    if(u0<0||u0>=n||v0<0||v0>=n||u0==v0||estimate<=0||estimate%SCALE!=0)return -1;
    int source=(int)u0,target=(int)v0;
    for(int mid=0;mid<n;mid++)for(int u=0;u<n;u++){if(distance[u*MAX_N+mid]==INF)continue;for(int v=0;v<n;v++){long cand=distance[u*MAX_N+mid]+distance[mid*MAX_N+v];if(cand<distance[u*MAX_N+v])distance[u*MAX_N+v]=cand;}}
    for(int u=0;u<n;u++)for(int v=0;v<n;v++)if(distance[u*MAX_N+v]==INF)return -1;
    if(estimate<distance[source*MAX_N+target]||estimate>768*distance[source*MAX_N+target])return -1;

    int[32] nearest;
    for(int x=0;x<n;x++){
        nearest[x]=x;
        for(int level=1;level<4;level++){
            int best=-1;
            for(int y=0;y<n;y++)if(((masks[level-1]>>y)&1)!=0){if(best<0||distance[x*MAX_N+y]<distance[x*MAX_N+best]||(distance[x*MAX_N+y]==distance[x*MAX_N+best]&&y<best))best=y;}
            nearest[level*MAX_N+x]=best;
        }
    }
    long[5] layers;layers[0]=full;layers[1]=masks[0];layers[2]=masks[1];layers[3]=masks[2];layers[4]=0;
    bool[64] bunch = zeroed;
    for(int center=0;center<n;center++)for(int level=0;level<4;level++){
        long boundary=INF;for(int y=0;y<n;y++)if(((layers[level+1]>>y)&1)!=0&&distance[center*MAX_N+y]<boundary)boundary=distance[center*MAX_N+y];
        for(int y=0;y<n;y++)if(((layers[level]>>y)&1)!=0&&((layers[level+1]>>y)&1)==0&&distance[center*MAX_N+y]<boundary)bunch[center*MAX_N+y]=true;
    }
    long value=estimate;int iu=even_index(source,value,&nearest[0],&distance[0]);
    if(!refine_further(source,target,iu,&nearest[0],&bunch[0],&distance[0]))return value;
    int iteration=0;while(refine_further(source,target,iu,&nearest[0],&bunch[0],&distance[0])&&iteration<=15){value=(2*value)/3;iu=even_index(source,value,&nearest[0],&distance[0]);iteration++;}
    int upper=even_index(source,(3*value)/2,&nearest[0],&distance[0]);if(upper<2)return -1;
    int pivot=nearest[source];if(bunch[target*MAX_N+pivot])return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot];
    pivot=nearest[MAX_N+target];if(bunch[source*MAX_N+pivot])return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot];
    pivot=nearest[upper*MAX_N+source];if(bunch[target*MAX_N+pivot])return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot];
    pivot=nearest[(upper+1)*MAX_N+target];return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot];
}
