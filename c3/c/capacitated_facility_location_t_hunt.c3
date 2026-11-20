module capacitated_facility_location_t_hunt;
const usz MAX_N=4; const usz MAX_F=3; const usz MAX_Q=4; const usz MAX_P=7;
const long NEG_INF=-2305843009213693952;

fn void write_word(uint8* out, usz at, long value) {
    ulong bits=(ulong)value;
    for(usz i=0;i<8;i+=1){out[at+i]=(uint8)(bits&255);bits>>=8;}
}

fn long capacitated_facility_location_t_hunt(long* in, usz len, uint8* out, usz cap) @export("capacitated_facility_location_t_hunt") {
    if(in==null||len<4||len>68)return -1;
    long nr=in[0],fr=in[1],qr=in[2],tr=in[3];
    if(nr<1||nr>4||fr<1||fr>3||qr<1||qr>4||tr<0||tr>=fr)return -1;
    usz n=(usz)nr,f=(usz)fr,q=(usz)qr,target=(usz)tr,points=n+f;
    if(len!=4+points*points+2*f+q+n)return -1;
    long[MAX_P][MAX_P] d=zeroed;long[MAX_F] fee=zeroed;long[MAX_F] caps=zeroed;
    usz[MAX_Q] kind=zeroed;usz[MAX_N] assigned=zeroed;usz pos=4;
    for(usz i=0;i<points;i+=1)for(usz j=0;j<points;j+=1){long v=in[pos];pos+=1;if(v<0||v>1000)return -1;d[i][j]=v;}
    for(usz i=0;i<points;i+=1){if(d[i][i]!=0)return -1;for(usz j=0;j<points;j+=1){if(i!=j&&d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<points;k+=1)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
    for(usz i=0;i<f;i+=1){fee[i]=in[pos];pos+=1;if(fee[i]<0||fee[i]>1000)return -1;}
    for(usz i=0;i<f;i+=1){caps[i]=in[pos];pos+=1;if(caps[i]<1||caps[i]>nr)return -1;}
    for(usz i=0;i<q;i+=1){long x=in[pos];pos+=1;if(x<0||x>=fr)return -1;kind[i]=(usz)x;}
    for(usz i=0;i<n;i+=1){long x=in[pos];pos+=1;if(x<0||x>=qr)return -1;assigned[i]=(usz)x;}
    long[MAX_Q] weight=zeroed;long[MAX_Q] profit=zeroed;long old=0;
    for(usz c=0;c<q;c+=1){profit[c]=fee[kind[c]];old+=fee[kind[c]];}
    for(usz u=0;u<n;u+=1){usz c=assigned[u],source=kind[c];weight[c]+=1;if(weight[c]>caps[source])return -1;long before=d[u][n+source],after=d[u][n+target];old+=before;profit[c]-=after-before;}
    long[5] result=zeroed;result[3]=old;result[4]=old;
    for(usz copies=1;copies<=n;copies+=1){usz limit=copies*(usz)caps[target];if(limit>n)limit=n;long[MAX_N+1] dp;long[MAX_N+1] next;ulong[MAX_N+1] masks;ulong[MAX_N+1] next_masks;
        for(usz w=0;w<=limit;w+=1){dp[w]=NEG_INF;masks[w]=0;}dp[0]=0;
        for(usz item=0;item<q;item+=1){for(usz w=0;w<=limit;w+=1){next[w]=dp[w];next_masks[w]=masks[w];}usz iw=(usz)weight[item];if(iw<=limit){for(usz w=0;w+iw<=limit;w+=1){if(dp[w]!=NEG_INF){usz nw=w+iw;long value=dp[w]+profit[item];ulong mask=masks[w]|(1ul<<item);if(value>next[nw]||(value==next[nw]&&mask<next_masks[nw])){next[nw]=value;next_masks[nw]=mask;}}}}for(usz w=0;w<=limit;w+=1){dp[w]=next[w];masks[w]=next_masks[w];}}
        long best=NEG_INF;ulong best_mask=0;for(usz w=0;w<=limit;w+=1){if(dp[w]>best||(dp[w]==best&&masks[w]<best_mask)){best=dp[w];best_mask=masks[w];}}
        if(best>(long)copies*fee[target]){result[0]=1;result[1]=(long)copies;result[2]=(long)best_mask;result[4]=old+(long)copies*fee[target]-best;break;}
    }
    if(out==null||cap<40)return -2;for(usz i=0;i<5;i+=1)write_word(out,8*i,result[i]);return 40;
}
