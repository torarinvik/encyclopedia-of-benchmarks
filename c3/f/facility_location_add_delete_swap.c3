module facility_location_add_delete_swap;
const usz MAX_TOTAL=8;const usz MAX_M=7;const usz MAX_INPUT=75;
fn void put(char* o,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;i+=1){o[at+i]=(char)(b&255);b>>=8;}}
fn bool lex_less(ulong a,ulong b,usz m){usz i=0,j=0;while(true){while(i<m&&(a&(1ul<<i))==0)i+=1;while(j<m&&(b&(1ul<<j))==0)j+=1;if(i==m||j==m)return i==m&&j!=m;if(i!=j)return i<j;i+=1;j+=1;}}
fn long objective(usz n,usz m,long[MAX_TOTAL][MAX_TOTAL]& d,long[MAX_M]& fee,ulong mask){long x=0;usz q=n+m;for(usz j=0;j<m;j+=1)if((mask&(1ul<<j))!=0)x+=fee[j];for(usz u=0;u<n;u+=1){long best=9223372036854775807;for(usz j=0;j<m;j+=1)if((mask&(1ul<<j))!=0&&d[u][n+j]<best)best=d[u][n+j];x+=best;}return x;}
fn void consider(ulong candidate,usz n,usz m,long[MAX_TOTAL][MAX_TOTAL]& d,long[MAX_M]& fee,ulong& best,long& best_cost){long c=objective(n,m,d,fee,candidate);if(c<best_cost||(c==best_cost&&lex_less(candidate,best,m))){best=candidate;best_cost=c;}}
long facility_location_add_delete_swap(long* in,usz len,char* out,usz cap) @export("facility_location_add_delete_swap") {
 if(in==null||len<4||len>MAX_INPUT)return -1;long n0=in[0],m0=in[1];if(n0<1||m0<1||n0+m0>8||n0>7||m0>7)return -1;usz n=n0.usz(),m=m0.usz(),q=n+m;if(len!=2+q*q+m+1)return -1;
 long[MAX_TOTAL][MAX_TOTAL] d=zeroed;long[MAX_M] fee=zeroed;usz p=2;for(usz i=0;i<q;i+=1)for(usz j=0;j<q;j+=1){long v=in[p];p+=1;if(v<0||v>1000)return -1;d[i][j]=v;}
 for(usz i=0;i<q;i+=1){if(d[i][i]!=0)return -1;for(usz j=0;j<q;j+=1){if(i!=j&&d[i][j]<=0)return -1;if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<q;k+=1)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
 for(usz j=0;j<m;j+=1){fee[j]=in[p];p+=1;if(fee[j]<0||fee[j]>1000)return -1;}long init=in[p];if(init<=0||(ulong)init>=(1ul<<m))return -1;ulong current=(ulong)init;long current_cost=objective(n,m,d,fee,current);
 for(usz pass=0;pass<(1ul<<m);pass+=1){ulong best=current;long best_cost=current_cost;for(usz j=0;j<m;j+=1){ulong bit=1ul<<j;if((current&bit)==0)consider(current|bit,n,m,d,fee,best,best_cost);else if((current&~bit)!=0){consider(current&~bit,n,m,d,fee,best,best_cost);for(usz k=0;k<m;k+=1){ulong other=1ul<<k;if((current&other)==0)consider((current&~bit)|other,n,m,d,fee,best,best_cost);}}}if(best_cost*10>=current_cost*9)break;current=best;current_cost=best_cost;}
 usz count=0;for(usz j=0;j<m;j+=1)if((current&(1ul<<j))!=0)count+=1;usz out_bytes=8*(2+n+count);if(out==null||cap<out_bytes)return -2;put(out,0,current_cost);put(out,8,count.long());usz at=16;for(usz j=0;j<m;j+=1)if((current&(1ul<<j))!=0){put(out,at,j.long());at+=8;}for(usz u=0;u<n;u+=1){usz best=0;long dist=9223372036854775807;for(usz j=0;j<m;j+=1)if((current&(1ul<<j))!=0&&d[u][n+j]<dist){dist=d[u][n+j];best=j;}put(out,at,best.long());at+=8;}return at.long();
}
