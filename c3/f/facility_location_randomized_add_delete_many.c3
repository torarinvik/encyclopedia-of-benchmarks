module facility_location_randomized_add_delete_many;
const usz MAX_N=5;const usz MAX_F=5;const usz MAX_Q=8;const usz MAX_P=10;const usz MAX_PARSEABLE=128;
fn void put(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i+=1){out[at+i]=(char)(bits&255);bits>>=8;}}
fn long state_cost(usz n,usz f,long[MAX_P][MAX_P]& d,long[MAX_N]& demand,long[MAX_N]& assignment,long[MAX_F]& fee,ulong mask){long total=0;for(usz s=0;s<f;s+=1)if(mask&(1ul<<s))total+=fee[s];for(usz j=0;j<n;j+=1)total+=demand[j]*d[j][n+assignment[j]];return total;}
fn long facility_location_randomized_add_delete_many(long* in,usz len,char* out,usz cap) @export("facility_location_randomized_add_delete_many"){
 if(in==null||len<12||len>MAX_PARSEABLE)return -1;long n0=in[0],f0=in[1],q0=in[2],raw=in[3];if(n0<1||n0>5||f0<1||f0>5||q0<1||q0>8||raw<=0||(ulong)raw>=(1ul<<f0))return -1;
 usz n=n0.usz(),f=f0.usz(),q=q0.usz(),p=n+f;if(len!=4+2*n+p*p+f+q)return -1;ulong mask=(ulong)raw;
 long[MAX_N] assignment=zeroed,demand=zeroed;long[MAX_P][MAX_P] d=zeroed;long[MAX_F] fee=zeroed;long[MAX_Q] tape=zeroed;usz at=4;
 for(usz j=0;j<n;j+=1){assignment[j]=in[at];at+=1;if(assignment[j]<0||assignment[j]>=f0||(mask&(1ul<<assignment[j]))==0)return -1;}
 for(usz j=0;j<n;j+=1){demand[j]=in[at];at+=1;if(demand[j]<1||demand[j]>10)return -1;}
 for(usz i=0;i<p;i+=1)for(usz j=0;j<p;j+=1){long v=in[at];at+=1;if(v<0||v>1000)return -1;d[i][j]=v;}
 for(usz i=0;i<p;i+=1){if(d[i][i]!=0)return -1;for(usz j=0;j<p;j+=1){if(i!=j&&d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<p;k+=1)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
 for(usz s=0;s<f;s+=1){fee[s]=in[at];at+=1;if(fee[s]<0||fee[s]>1000)return -1;}for(usz t=0;t<q;t+=1){tape[t]=in[at];at+=1;if(tape[t]<0||tape[t]>=f0)return -1;}
 long[MAX_Q] costs=zeroed,accepted=zeroed;long current=state_cost(n,f,d,demand,assignment,fee,mask),count=0;
 for(usz step=0;step<q;step+=1){usz candidate=tape[step].usz();ulong bit=1ul<<candidate;long did=0;if((mask&bit)==0){bool[MAX_N] closer=zeroed;long gain=-fee[candidate];for(usz j=0;j<n;j+=1){usz old=assignment[j].usz();if(d[j][n+candidate]<d[j][n+old]){closer[j]=true;gain+=demand[j]*(d[j][n+old]-d[j][n+candidate]);}}
 ulong drop=0;for(usz s=0;s<f;s+=1)if(mask&(1ul<<s)){long cg=fee[s];for(usz j=0;j<n;j+=1)if(assignment[j]==s&&!closer[j])cg+=demand[j]*(d[j][n+s]-d[j][n+candidate]);if(cg>0){drop|=1ul<<s;gain+=cg;}}
 if(gain>0){mask=(mask|bit)&~drop;for(usz j=0;j<n;j+=1)if(closer[j]||(drop&(1ul<<assignment[j]))!=0)assignment[j]=candidate.long();current=state_cost(n,f,d,demand,assignment,fee,mask);did=1;count+=1;}}
 costs[step]=current;accepted[step]=did;}
 usz bytes=8*(2*q+3+n);if(out==null||cap<bytes)return -2;at=0;for(usz t=0;t<q;t+=1){put(out,at,costs[t]);at+=8;}for(usz t=0;t<q;t+=1){put(out,at,accepted[t]);at+=8;}put(out,at,current);at+=8;put(out,at,mask.long());at+=8;for(usz j=0;j<n;j+=1){put(out,at,assignment[j]);at+=8;}put(out,at,count);at+=8;return at.long();
}
