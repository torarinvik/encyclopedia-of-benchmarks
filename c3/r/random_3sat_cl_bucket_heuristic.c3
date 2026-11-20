module random_3sat_cl_bucket_heuristic;

const int MAX_N=8; const int MAX_M=24; const int MAX_PARSEABLE_IN=99; const int MAX_WORDS=44;
struct Event { long literal; long kind; long bi; long bj; }

fn void put_i64(char *out, usz at, long value) {
    ulong bits=(ulong)value;
    for(usz b=0;b<8;b++){out[at+b]=(char)(bits&255);bits>>=8;}
}

fn bool reduce(int *lits,int *lens,bool *active,int m,int *assigned,int literal) {
    int v=(literal>0?literal:-literal)-1; int value=literal>0?1:-1;
    if(assigned[v]!=0&&assigned[v]!=value)return false; assigned[v]=value;
    for(int c=0;c<m;c++){
        if(!active[c])continue; bool satisfied=false;
        for(int j=0;j<lens[c];j++)if(lits[3*c+j]==literal)satisfied=true;
        if(satisfied){active[c]=false;continue;}
        int kept=0;for(int j=0;j<lens[c];j++)if(lits[3*c+j]!=-literal){lits[3*c+kept]=lits[3*c+j];kept++;}
        lens[c]=kept;if(kept==0)return false;
    }
    return true;
}

fn bool propagate(int *lits,int *lens,bool *active,int m,int *assigned,
                  Event[MAX_N] *events,int *count,bool record) {
    while(true){int unit=0;for(int c=0;c<m;c++)if(active[c]&&lens[c]==1){unit=lits[3*c];break;}
        if(unit==0)return true;
        if(record){events[*count].literal=unit;events[*count].kind=1;events[*count].bi=-1;events[*count].bj=-1;(*count)++;}
        if(!reduce(lits,lens,active,m,assigned,unit))return false;
    }
}

fn void degrees(int *lits,int *lens,bool *active,int m,int n,int *pos,int *neg) {
    for(int v=0;v<n;v++){pos[v]=0;neg[v]=0;}
    for(int c=0;c<m;c++)if(active[c])for(int j=0;j<lens[c];j++){int x=lits[3*c+j];int v=(x>0?x:-x)-1;if(x>0)pos[v]++;else neg[v]++;}
}

fn int bucket_literal(int *lits,int *lens,bool *active,int m,int n,int *assigned,int bi,int bj) {
    int[MAX_N] pos=zeroed;int[MAX_N] neg=zeroed;degrees(lits,lens,active,m,n,&pos[0],&neg[0]);
    for(int v=0;v<n;v++){if(assigned[v]!=0)continue;int p=pos[v]<10?pos[v]:10;int q=neg[v]<10?neg[v]:10;
        if(p==bi&&q==bj)return v+1;if(q==bi&&p==bj)return -(v+1);}
    return 0;
}

fn void flows(int *lits,int *lens,bool *active,int m,int n,long *s2,long *s3,long *den) {
    long[MAX_N] p2=zeroed;long[MAX_N] n2=zeroed;long[MAX_N] p3=zeroed;long[MAX_N] n3=zeroed;int c2=0;
    for(int c=0;c<m;c++)if(active[c]){if(lens[c]==2){c2++;for(int j=0;j<2;j++){int x=lits[3*c+j];int v=(x>0?x:-x)-1;if(x>0)p2[v]++;else n2[v]++;}}
        else if(lens[c]==3){for(int j=0;j<3;j++){int x=lits[3*c+j];int v=(x>0?x:-x)-1;if(x>0)p3[v]++;else n3[v]++;}}}
    *s2=0;*s3=0;for(int c=0;c<m;c++)if(active[c]&&lens[c]==2)for(int j=0;j<2;j++){int x=-lits[3*c+j];int v=(x>0?x:-x)-1;if(x>0){*s2+=p2[v];*s3+=p3[v];}else{*s2+=n2[v];*s3+=n3[v];}}
    *den=c2==0?1:2*c2;(void)n;
}

fn bool choose_bucket(int *lits,int *lens,bool *active,int m,int n,int *assigned,int *best_i,int *best_j) {
    long old2,old3,oldden;flows(lits,lens,active,m,n,&old2,&old3,&oldden);bool found=false;long best_num=0,best_den=1;
    for(int bi=0;bi<=10;bi++)for(int bj=0;bj<=10;bj++){
        int literal=bucket_literal(lits,lens,active,m,n,assigned,bi,bj);if(literal==0)continue;
        int[3][MAX_M] tlits=zeroed;int[MAX_M] tlens=zeroed;bool[MAX_M] tactive=zeroed;int[MAX_N] tassigned=zeroed;
        for(int c=0;c<m;c++){tlens[c]=lens[c];tactive[c]=active[c];for(int j=0;j<3;j++)tlits[c][j]=lits[3*c+j];}
        for(int v=0;v<n;v++)tassigned[v]=assigned[v];Event[MAX_N] ignored=zeroed;int ignored_count=0;
        if(!reduce(&tlits[0][0],&tlens[0],&tactive[0],m,&tassigned[0],literal))continue;
        if(!propagate(&tlits[0][0],&tlens[0],&tactive[0],m,&tassigned[0],&ignored,&ignored_count,false))continue;
        long next2,next3,nextden;flows(&tlits[0][0],&tlens[0],&tactive[0],m,n,&next2,&next3,&nextden);
        long num=next2*oldden-old2*nextden;long den=next3*oldden-old3*nextden;if(den==0)continue;if(den<0){num=-num;den=-den;}
        if(!found||num*best_den>best_num*den||(num*best_den==best_num*den&&(bi<*best_i||(bi==*best_i&&bj<*best_j)))){found=true;best_num=num;best_den=den;*best_i=bi;*best_j=bj;}
    }
    return found;
}

fn long random_3sat_cl_bucket_heuristic(long *input,usz length,char *output,usz capacity) @export("random_3sat_cl_bucket_heuristic") {
    if(input==null||length<2||length>MAX_PARSEABLE_IN)return -1;
    if(input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>MAX_M)return -1;
    int n=(int)input[0],m=(int)input[1];if(length!=(usz)(2+4*m))return -1;
    int[3][MAX_M] lits=zeroed;int[MAX_M] lens=zeroed;bool[MAX_M] active=zeroed;
    for(int c=0;c<m;c++){long rk=input[2+4*c];if(rk<1||rk>3)return -1;int k=(int)rk;bool[MAX_N] seen=zeroed;
        for(int j=0;j<3;j++){long raw=input[2+4*c+1+j];if(j<k){if(raw==0||raw< -n||raw>n)return -1;int v=(int)(raw>0?raw:-raw)-1;if(seen[v])return -1;seen[v]=true;lits[c][j]=(int)raw;}else if(raw!=0)return -1;}
        lens[c]=k;active[c]=true;}
    int[MAX_N] assigned=zeroed;Event[MAX_N] events=zeroed;int count=0;int status=0;
    if(!propagate(&lits[0][0],&lens[0],&active[0],m,&assigned[0],&events,&count,true))status=1;
    while(status==0){bool pending=false;for(int v=0;v<n;v++)if(assigned[v]==0)pending=true;if(!pending)break;
        int bi=-1,bj=-1;if(!choose_bucket(&lits[0][0],&lens[0],&active[0],m,n,&assigned[0],&bi,&bj)){status=2;break;}
        int literal=bucket_literal(&lits[0][0],&lens[0],&active[0],m,n,&assigned[0],bi,bj);if(literal==0){status=2;break;}
        events[count].literal=literal;events[count].kind=0;events[count].bi=bi;events[count].bj=bj;count++;
        if(!reduce(&lits[0][0],&lens[0],&active[0],m,&assigned[0],literal)){status=1;break;}
        if(!propagate(&lits[0][0],&lens[0],&active[0],m,&assigned[0],&events,&count,true)){status=1;break;}}
    long[MAX_WORDS] words=zeroed;int at=0;words[at++]=status;words[at++]=n;int assigned_count=0;for(int v=0;v<n;v++)if(assigned[v]!=0)assigned_count++;words[at++]=assigned_count;
    for(int v=0;v<n;v++)words[at++]=assigned[v];words[at++]=count;for(int i=0;i<count;i++){words[at++]=events[i].literal;words[at++]=events[i].kind;words[at++]=events[i].bi;words[at++]=events[i].bj;}
    usz bytes=(usz)(8*at);if(output==null||capacity<bytes)return -2;char[352] staged=zeroed;for(int i=0;i<at;i++)put_i64(&staged[0],(usz)(8*i),words[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
