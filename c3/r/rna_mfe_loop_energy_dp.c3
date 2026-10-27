module rna_mfe_loop_energy_dp;

const usz MAX_N=12; const usz MAX_PAIRS=36; const usz TABLE_VALUES=234; const usz MAX_INPUT=247; const usz MAX_OUTPUT=112;
const long INF=1152921504606846976;

fn int pair_type(long left,long right) {
    if(left==0&&right==3)return 0;if(left==3&&right==0)return 1;
    if(left==1&&right==2)return 2;if(left==2&&right==1)return 3;
    if(left==2&&right==3)return 4;if(left==3&&right==2)return 5;return -1;
}
fn bool lex_less(ulong left,ulong right,usz count) {
    usz li=0,ri=0;
    while(true){while(li<count&&((left>>li)&1)==0)li+=1;while(ri<count&&((right>>ri)&1)==0)ri+=1;
        if(li==count||ri==count)return li==count&&ri<count;if(li!=ri)return li<ri;li+=1;ri+=1;}
}
fn long loop_cost(long *input,usz n,int kind,int unpaired,int children){return input[1+n+(usz)kind*39+(usz)unpaired*3+(usz)children];}
fn void put64(char *out,usz pos,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[pos+b]=(char)(bits&255);bits>>=8;}}

long rna_mfe_loop_energy_dp(long *input,usz length,char *output,usz capacity) @export("rna_mfe_loop_energy_dp") {
    if(input==null||length<239||length>MAX_INPUT)return -1;
    long n64=input[0];if(n64<4||n64>12||length!=1+(usz)n64+TABLE_VALUES)return -1;usz n=(usz)n64;
    long[MAX_N] bases=zeroed;for(usz i=0;i<n;i+=1){bases[i]=input[1+i];if(bases[i]<0||bases[i]>3)return -1;}
    for(usz i=1+n;i<length;i+=1)if(input[i]<-1000||input[i]>1000)return -1;
    int[MAX_N][MAX_N] types=zeroed;int[MAX_N][MAX_N] ids=zeroed;
    for(usz i=0;i<MAX_N;i+=1)for(usz j=0;j<MAX_N;j+=1){types[i][j]=-1;ids[i][j]=-1;}
    int[MAX_PAIRS] pair_i=zeroed;int[MAX_PAIRS] pair_j=zeroed;usz pair_count=0;
    for(usz i=0;i<n;i+=1)for(usz j=i+4;j<n;j+=1){int kind=pair_type(bases[i],bases[j]);if(kind>=0){types[i][j]=kind;ids[i][j]=(int)pair_count;pair_i[pair_count]=(int)i;pair_j[pair_count]=(int)j;pair_count+=1;}}
    long[MAX_N][MAX_N] ve=zeroed;ulong[MAX_N][MAX_N] vm=zeroed;
    for(usz i=0;i<MAX_N;i+=1)for(usz j=0;j<MAX_N;j+=1)ve[i][j]=INF;
    for(usz span=4;span<n;span+=1)for(usz i=0;i+span<n;i+=1){usz j=i+span;int kind=types[i][j];if(kind<0)continue;ulong outer=(ulong)1<<(usz)ids[i][j];long best=INF;ulong best_mask=0;
        long candidate=loop_cost(input,n,kind,(int)span-1,0);if(candidate<best||(candidate==best&&lex_less(outer,best_mask,pair_count))){best=candidate;best_mask=outer;}
        for(usz a=i+1;a<j;a+=1)for(usz b=a+4;b<j;b+=1){if(ids[a][b]<0||ve[a][b]==INF)continue;int unpaired=(int)(a-i-1+j-b-1);candidate=loop_cost(input,n,kind,unpaired,1)+ve[a][b];ulong mask=outer|vm[a][b];if(candidate<best||(candidate==best&&lex_less(mask,best_mask,pair_count))){best=candidate;best_mask=mask;}}
        for(usz a=i+1;a<j;a+=1)for(usz b=a+4;b<j;b+=1){if(ids[a][b]<0||ve[a][b]==INF)continue;for(usz c=b+1;c<j;c+=1)for(usz d=c+4;d<j;d+=1){if(ids[c][d]<0||ve[c][d]==INF)continue;int unpaired=(int)(a-i-1+c-b-1+j-d-1);candidate=loop_cost(input,n,kind,unpaired,2)+ve[a][b]+ve[c][d];ulong mask=outer|vm[a][b]|vm[c][d];if(candidate<best||(candidate==best&&lex_less(mask,best_mask,pair_count))){best=candidate;best_mask=mask;}}}
        ve[i][j]=best;vm[i][j]=best_mask;
    }
    long[MAX_N] we=zeroed;ulong[MAX_N] wm=zeroed;
    for(usz j=0;j<n;j+=1){long best=0;ulong best_mask=0;if(j>0){best=we[j-1];best_mask=wm[j-1];}
        for(usz i=0;i+4<=j;i+=1){if(types[i][j]<0||ve[i][j]==INF)continue;long prefix=0;ulong prefix_mask=0;if(i>0){prefix=we[i-1];prefix_mask=wm[i-1];}long value=prefix+ve[i][j];ulong mask=prefix_mask|vm[i][j];if(value<best||(value==best&&lex_less(mask,best_mask,pair_count))){best=value;best_mask=mask;}}
        we[j]=best;wm[j]=best_mask;
    }
    long count=0;for(usz p=0;p<pair_count;p+=1)if((wm[n-1]>>p)&1)count+=1;usz bytes=8*(2+2*(usz)count);if(output==null||capacity<bytes)return -2;
    char[MAX_OUTPUT] staged=zeroed;put64(&staged[0],0,we[n-1]);put64(&staged[0],8,count);usz at=2;
    for(usz p=0;p<pair_count;p+=1)if((wm[n-1]>>p)&1){put64(&staged[0],8*at,pair_i[p]);at+=1;put64(&staged[0],8*at,pair_j[p]);at+=1;}
    for(usz b=0;b<bytes;b+=1)output[b]=staged[b];return (long)bytes;
}
