module capacitated_facility_location_t_hunt_local_search;
const usz MAX_N=4; const usz MAX_F=3; const usz MAX_Q=4; const usz MAX_COPIES=644;
const usz MAX_CANDIDATE=648; const usz MAX_P=7; const usz PARSEABLE=63;
const long NEG=-2305843009213693952;

fn void put_word(uint8* out, usz at, long value) {
    ulong bits=(ulong)value;
    for(usz b=0;b<8;b+=1){out[at+b]=(uint8)(bits&255);bits>>=8;}
}

fn long assign_state(usz n, usz f, long[MAX_P][MAX_P]& d, long[MAX_F]& fee,
    long[MAX_F]& caps, long[MAX_CANDIDATE]& types, usz copies, long[MAX_N]& assignment) {
    usz[MAX_F] multiplicity=zeroed;
    for(usz i=0;i<copies;i+=1)multiplicity[(usz)types[i]]+=1;
    usz combinations=1;for(usz j=0;j<n;j+=1)combinations*=f;
    long best=9223372036854775807;long[MAX_N] best_types=zeroed;
    for(usz code=0;code<combinations;code+=1){usz rem=code;long[MAX_N] candidate=zeroed;usz[MAX_F] loads=zeroed;long service=0;
        for(usz j=n;j>0;){j-=1;usz kind=rem%f;rem/=f;candidate[j]=(long)kind;loads[kind]+=1;service+=d[j][n+kind];}
        bool feasible=true;for(usz kind=0;kind<f;kind+=1)if(loads[kind]>multiplicity[kind]*(usz)caps[kind])feasible=false;
        if(feasible&&service<best){best=service;for(usz j=0;j<n;j+=1)best_types[j]=candidate[j];}
    }
    usz[MAX_CANDIDATE] copy_load=zeroed;
    for(usz j=0;j<n;j+=1){assignment[j]=-1;for(usz i=0;i<copies;i+=1){usz kind=(usz)types[i];if(kind==(usz)best_types[j]&&copy_load[i]<(usz)caps[kind]){assignment[j]=(long)i;copy_load[i]+=1;break;}}}
    for(usz i=0;i<copies;i+=1)best+=fee[(usz)types[i]];
    return best;
}

fn usz insert_type(long* types, usz count, long kind) {
    usz at=count;while(at>0&&types[at-1]>kind){types[at]=types[at-1];at-=1;}types[at]=kind;return count+1;
}

fn long hunt(usz n, long[MAX_P][MAX_P]& d, long[MAX_F]& fee,
    long[MAX_F]& caps, long[MAX_CANDIDATE]& types, usz copies, long[MAX_N]& assignment,
    usz target, usz l, usz* loads, long* profits,
    bool[MAX_COPIES][MAX_N+1]& take, bool* selected) {
    for(usz i=0;i<copies;i+=1){loads[i]=0;profits[i]=fee[(usz)types[i]];}
    for(usz j=0;j<n;j+=1){usz copy=(usz)assignment[j];loads[copy]+=1;usz old=(usz)types[copy];profits[copy]+=d[j][n+old]-d[j][n+target];}
    usz limit=l*(usz)caps[target];if(limit>n)limit=n;
    long[MAX_N+1] dp;long[MAX_N+1] next;for(usz w=0;w<=limit;w+=1)dp[w]=NEG;dp[0]=0;
    for(usz i=0;i<copies;i+=1){for(usz w=0;w<=limit;w+=1){next[w]=dp[w];take[i][w]=false;}
        for(usz w=0;w<=limit;w+=1){if(dp[w]==NEG||w+loads[i]>limit)continue;usz nw=w+loads[i];long value=dp[w]+profits[i];if(value>next[nw]){next[nw]=value;take[i][nw]=true;}}
        for(usz w=0;w<=limit;w+=1)dp[w]=next[w];}
    long best=NEG;usz best_weight=0;for(usz w=0;w<=limit;w+=1)if(dp[w]>best){best=dp[w];best_weight=w;}
    for(usz i=0;i<copies;i+=1)selected[i]=false;
    for(usz i=copies;i>0;){i-=1;if(take[i][best_weight]){selected[i]=true;best_weight-=loads[i];}}
    return best;
}

fn long capacitated_facility_location_t_hunt_local_search(long* in, usz len,
    uint8* out, usz cap) @export("capacitated_facility_location_t_hunt_local_search") {
    if(in==null||len<10||len>PARSEABLE)return -1;
    long nr=in[0],fr=in[1],qr=in[2];if(nr<1||nr>4||fr<1||fr>3||qr<1||qr>4)return -1;
    usz n=(usz)nr,f=(usz)fr,q=(usz)qr,p=n+f;if(len!=3+p*p+2*f+q)return -1;
    long[MAX_P][MAX_P] d=zeroed;long[MAX_F] fee=zeroed;long[MAX_F] caps=zeroed;long[MAX_CANDIDATE] types=zeroed;usz at=3;
    for(usz i=0;i<p;i+=1)for(usz j=0;j<p;j+=1){long x=in[at];at+=1;if(x<0||x>20)return -1;d[i][j]=x;}
    for(usz i=0;i<p;i+=1){if(d[i][i]!=0)return -1;for(usz j=0;j<p;j+=1){if(i!=j&&d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<p;k+=1)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
    for(usz i=0;i<f;i+=1){fee[i]=in[at];at+=1;if(fee[i]<0||fee[i]>20)return -1;}
    for(usz i=0;i<f;i+=1){caps[i]=in[at];at+=1;if(caps[i]<1||caps[i]>nr)return -1;}
    usz copies=q,total_capacity=0;for(usz i=0;i<q;i+=1){types[i]=in[at];at+=1;if(types[i]<0||types[i]>=fr)return -1;total_capacity+=(usz)caps[(usz)types[i]];}
    if(total_capacity<n)return -1;
    for(usz i=1;i<copies;i+=1){long value=types[i];usz j=i;while(j>0&&types[j-1]>value){types[j]=types[j-1];j-=1;}types[j]=value;}
    long[MAX_N] assignment=zeroed;long current=assign_state(n,f,d,fee,caps,types,copies,assignment);usz steps=0;
    while(steps<160){bool moved=false;for(usz target=0;target<f;target+=1){long[MAX_CANDIDATE] candidate_types=zeroed;for(usz i=0;i<copies;i+=1)candidate_types[i]=types[i];usz candidate_count=copies;candidate_count=insert_type(&candidate_types[0],candidate_count,(long)target);long[MAX_N] candidate_assignment=zeroed;long candidate_cost=assign_state(n,f,d,fee,caps,candidate_types,candidate_count,candidate_assignment);
        if(candidate_cost<current){for(usz i=0;i<candidate_count;i+=1)types[i]=candidate_types[i];copies=candidate_count;current=candidate_cost;for(usz j=0;j<n;j+=1)assignment[j]=candidate_assignment[j];steps+=1;moved=true;break;}
        usz[MAX_COPIES] loads=zeroed;long[MAX_COPIES] profits=zeroed;bool[MAX_COPIES][MAX_N+1] take=zeroed;bool[MAX_COPIES] selected=zeroed;
        for(usz l=1;l<=n;l+=1){long profit=hunt(n,d,fee,caps,types,copies,assignment,target,l,&loads[0],&profits[0],take,&selected[0]);if(profit<=(long)l*fee[target])continue;
            usz drop_count=0;for(usz i=0;i<copies;i+=1)if(!selected[i])candidate_types[drop_count++]=types[i];candidate_count=drop_count;for(usz k=0;k<l;k+=1)candidate_count=insert_type(&candidate_types[0],candidate_count,(long)target);
            candidate_cost=assign_state(n,f,d,fee,caps,candidate_types,candidate_count,candidate_assignment);if(candidate_cost<current){for(usz i=0;i<candidate_count;i+=1)types[i]=candidate_types[i];copies=candidate_count;current=candidate_cost;for(usz j=0;j<n;j+=1)assignment[j]=candidate_assignment[j];steps+=1;moved=true;break;}}
        if(moved)break;}if(!moved)break;}
    usz bytes=8*(3+copies+n);if(out==null||cap<bytes)return -2;at=0;put_word(out,at,current);at+=8;put_word(out,at,(long)steps);at+=8;put_word(out,at,(long)copies);at+=8;for(usz i=0;i<copies;i+=1){put_word(out,at,types[i]);at+=8;}for(usz j=0;j<n;j+=1){put_word(out,at,assignment[j]);at+=8;}return (long)bytes;
}
