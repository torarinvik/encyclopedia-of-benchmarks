module fm_index_count;

fn bool suffix_less(long* s, usz n, usz a0, usz b0) {
    usz a=a0, b=b0;
    while (a<n && b<n) { if (s[a]!=s[b]) return s[a]<s[b]; a++; b++; }
    return a==n && b!=n;
}

fn long fm_index_count(long* input, usz length, uint8* output, usz capacity)
        @export("fm_index_count") {
    if (input==null || length<4 || length>42) return -1;
    long n0=input[0]; if (n0<1 || n0>32 || length<(usz)n0+3) return -1;
    usz n=(usz)n0, m_at=n+1; long m0=input[m_at];
    if (m0<1 || m0>8 || length!=n+1+(usz)m0+1) return -1;
    usz m=(usz)m0, total=n+1;
    long[33] s; long[8] pattern;
    for (usz i=0;i<n;i++) { if(input[1+i]<1||input[1+i]>4)return -1; s[i]=input[1+i]; }
    for (usz i=0;i<m;i++) { if(input[m_at+1+i]<1||input[m_at+1+i]>4)return -1; pattern[i]=input[m_at+1+i]; }
    s[n]=0;
    if(output==null||capacity<8)return -2;
    usz[33] sa;
    for(usz i=0;i<total;i++)sa[i]=i;
    for(usz i=1;i<total;i++) {
        usz key=sa[i], j=i;
        while(j>0&&suffix_less(&s[0],total,key,sa[j-1])){sa[j]=sa[j-1];j--;}
        sa[j]=key;
    }
    long[33] bwt; usz[5] freq = zeroed;
    for(usz i=0;i<total;i++){bwt[i]=s[(sa[i]+total-1)%total];freq[(usz)bwt[i]]++;}
    usz[5] cumulative; usz sum=0;
    for(usz x=0;x<5;x++){cumulative[x]=sum;sum+=freq[x];}
    usz left=0,right=total;
    for(usz k=0;k<m;k++){
        usz symbol=(usz)pattern[m-1-k], rl=0,rr=0;
        for(usz i=0;i<left;i++)if((usz)bwt[i]==symbol)rl++;
        for(usz i=0;i<right;i++)if((usz)bwt[i]==symbol)rr++;
        left=cumulative[symbol]+rl;right=cumulative[symbol]+rr;
        if(left==right)break;
    }
    ulong count=(ulong)(right-left);
    for(usz i=0;i<8;i++)output[i]=(uint8)(count>>(8*i));
    return 8;
}
