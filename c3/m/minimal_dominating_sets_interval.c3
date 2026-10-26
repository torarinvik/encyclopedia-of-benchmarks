module minimal_dominating_sets_interval;

fn bool intersects(long* s, long* e, usz a, usz b) { return s[a] <= e[b] && s[b] <= e[a]; }

fn long minimal_dominating_sets_interval(long* input, usz length, uint8* output, usz capacity)
        @export("minimal_dominating_sets_interval") {
    if(input==null||length<3||length>25)return -1;
    long n0=input[0];if(n0<1||n0>12||length!=1+2*(usz)n0)return -1;
    usz n=(usz)n0;long[12] s;long[12] e;long min_end=0,max_start=0;
    for(usz i=0;i<n;i++){
        s[i]=input[1+2*i];e[i]=input[2+2*i];
        if(s[i]<-100||s[i]>100||e[i]<-100||e[i]>100||s[i]>=e[i]||(i>0&&s[i-1]>=s[i]))return -1;
        if(i==0||e[i]<min_end)min_end=e[i];if(i==0||s[i]>max_start)max_start=s[i];
        for(usz j=0;j<i;j++)if(s[i]==s[j]||s[i]==e[j]||e[i]==s[j]||e[i]==e[j])return -1;
    }
    if(output==null||capacity<8)return -2;
    bool[12] has_next=zeroed;long[12] ncs=zeroed;long[12] nce=zeroed;long[12] p_single;
    for(usz i=0;i<n;i++){
        p_single[i]=0x7fffffffffffffff;
        for(usz z=0;z<n;z++){
            if(intersects(&s[0],&e[0],i,z)&&e[z]<p_single[i])p_single[i]=e[z];
            if(s[z]>e[i]){if(!has_next[i]||s[z]<ncs[i])ncs[i]=s[z];if(!has_next[i]||e[z]<nce[i])nce[i]=e[z];has_next[i]=true;}
        }
    }
    bool[12][12] valid=zeroed;long[12][12] p_pair;
    for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++){
        p_pair[i][j]=0x7fffffffffffffff;
        for(usz z=0;z<n;z++)if(intersects(&s[0],&e[0],j,z)&&!intersects(&s[0],&e[0],i,z)&&e[z]<p_pair[i][j])p_pair[i][j]=e[z];
        valid[i][j]=has_next[i]&&p_single[i]<s[j]&&s[j]<=nce[i]&&e[j]>=ncs[i];
    }
    long[12][12] ways=zeroed;
    for(usz j=1;j<n;j++)for(usz i=0;i<j;i++){
        if(!valid[i][j])continue;if(s[i]<=min_end)ways[i][j]++;
        for(usz k=j+1;k<n;k++)if(valid[j][k]&&p_pair[i][j]<s[k]&&s[k]<=nce[j])ways[j][k]+=ways[i][j];
    }
    long count=0;for(usz i=0;i<n;i++)if(s[i]<=min_end&&e[i]>=max_start)count++;
    for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++)if(e[j]>=max_start)count+=ways[i][j];
    ulong bits=(ulong)count;for(usz b=0;b<8;b++)output[b]=(uint8)(bits>>(8*b));return 8;
}
