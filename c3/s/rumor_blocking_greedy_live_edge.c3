module rumor_blocking_greedy_live_edge;

const int MAX_N=8,MAX_M=16,MAX_WORLDS=8;

fn void put_i64(char* out,usz word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[word*8+b]=(char)((bits>>(b*8))&255);}
fn int infected_count(int n,int m,int world,uint sources,uint protectors,int[MAX_M] eu,int[MAX_M] ev,int[MAX_M] masks){
    int[MAX_N] status={0};bool[MAX_N] rf={false},pf={false};
    for(int v=0;v<n;v++){if(sources&(1U<<v)){status[v]=1;rf[v]=true;}if(protectors&(1U<<v)){status[v]=2;pf[v]=true;}}
    for(int step=0;step<n;step++){
        bool[MAX_N] rp={false},pp={false},nr={false},np={false};
        for(int e=0;e<m;e++){int u=eu[e],v=ev[e];if(status[v]!=0)continue;if(pf[u])pp[v]=true;if(rf[u]&&(masks[e]&(1<<world))!=0)rp[v]=true;}
        bool changed=false;
        for(int v=0;v<n;v++){if(status[v]!=0)continue;if(pp[v]){status[v]=2;np[v]=true;changed=true;}else if(rp[v]){status[v]=1;nr[v]=true;changed=true;}}
        rf=nr;pf=np;if(!changed)break;
    }
    int count=0;for(int v=0;v<n;v++)if(status[v]==1)count++;return count;
}

fn long rumor_blocking_greedy_live_edge(long* input,usz input_length,char* output,usz output_capacity) @export("rumor_blocking_greedy_live_edge"){
    if(input==null||input_length<5||input_length>61)return -1;
    long n0=input[0],m0=input[1],r0=input[2],k0=input[3],w0=input[4];
    if(n0<2||n0>8||m0<0||m0>16||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>8||k0>n0-r0||input_length!=(usz)(5+r0+3*m0))return -1;
    int n=(int)n0,m=(int)m0,r=(int)r0,k=(int)k0,worlds=(int)w0;uint sources=0;
    for(int i=0;i<r;i++){long v=input[5+i];if(v<0||v>=n||sources&(1U<<(int)v))return -1;sources|=1U<<(int)v;}
    int[MAX_M] eu={0},ev={0},masks={0};bool[MAX_N][MAX_N] seen={false};usz at=(usz)(5+r);int allowed=(1<<worlds)-1;
    for(int e=0;e<m;e++){long u=input[at+3*e],v=input[at+3*e+1],mask=input[at+3*e+2];if(u<0||u>=n||v<0||v>=n||u==v||mask<0||mask>allowed)return -1;if(seen[(int)u][(int)v])return -1;seen[(int)u][(int)v]=true;eu[e]=(int)u;ev[e]=(int)v;masks[e]=(int)mask;}
    int[MAX_WORLDS] baseline={0};for(int w=0;w<worlds;w++)baseline[w]=infected_count(n,m,w,sources,0,eu,ev,masks);
    uint selected=0;int[MAX_N] chosen={0},scores={0};
    for(int round=0;round<k;round++){
        int[MAX_WORLDS] current={0};for(int w=0;w<worlds;w++)current[w]=baseline[w]-infected_count(n,m,w,sources,selected,eu,ev,masks);
        int best=-1,best_score=-1;
        for(int candidate=0;candidate<n;candidate++){uint bit=1U<<candidate;if(sources&bit||selected&bit)continue;int score=0;for(int w=0;w<worlds;w++)score+=baseline[w]-infected_count(n,m,w,sources,selected|bit,eu,ev,masks)-current[w];if(score>best_score){best=candidate;best_score=score;}}
        if(best<0)return -1;selected|=1U<<best;chosen[round]=best;scores[round]=best_score;
    }
    usz bytes=(usz)(1+2*k)*8;if(output==null||output_capacity<bytes)return -2;put_i64(output,0,k);
    for(int i=0;i<k;i++){put_i64(output,(usz)(1+2*i),chosen[i]);put_i64(output,(usz)(2+2*i),scores[i]);}return (long)bytes;
}
