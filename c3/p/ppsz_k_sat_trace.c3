module ppsz_k_sat_trace;
const int MAX_N=8;const int MAX_CLAUSES=12;const int MAX_INPUT=54;const int MAX_OUTPUT=72;
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;}}
fn int fixed_mask(int mask,int[MAX_N] assigned,int n){for(int i=0;i<n;i++){if(assigned[i]>=0){if(assigned[i]==1)mask|=1<<i;else mask&=~(1<<i);}}return mask;}
fn bool clause_true(long[3] clause,int mask){for(int j=0;j<3;j++){long lit=clause[j];int bit=(mask>>((int)(lit>0?lit:-lit)-1))&1;if((lit>0&&bit==1)||(lit<0&&bit==0))return true;}return false;}
fn bool selected_true(long[MAX_CLAUSES][3] clauses,int m,int subset,int mask){for(int i=0;i<m;i++){if((subset&(1<<i))!=0&&!clause_true(clauses[i],mask))return false;}return true;}
fn int popcount(int value){int count=0;while(value>0){count+=value&1;value>>=1;}return count;}
fn bool current_sat(int n,int m,long[MAX_CLAUSES][3] clauses,int[MAX_N] assigned){for(int mask=0;mask<(1<<n);mask++){if(selected_true(clauses,m,(1<<m)-1,fixed_mask(mask,assigned,n)))return true;}return false;}
fn bool find_force(int n,int m,long[MAX_CLAUSES][3] clauses,int[MAX_N] assigned,int* forced_var,int* forced_value){
 if(!current_sat(n,m,clauses,assigned))return false;int threshold=0;while((1<<(threshold+1))<=n)threshold++;int[MAX_N] implied={};for(int i=0;i<MAX_N;i++)implied[i]=-1;
 for(int subset=1;subset<(1<<m);subset++){if(popcount(subset)>threshold)continue;int[MAX_N] zero={},one={};
  for(int mask=0;mask<(1<<n);mask++){int full=fixed_mask(mask,assigned,n);if(selected_true(clauses,m,subset,full)){for(int x=0;x<n;x++){if(assigned[x]<0){if((full>>x)&1)one[x]=1;else zero[x]=1;}}}}
  for(int x=0;x<n;x++){if(assigned[x]<0&&zero[x]!=one[x]&&implied[x]<0)implied[x]=one[x]?1:0;}}
 for(int x=0;x<n;x++){if(implied[x]>=0){*forced_var=x;*forced_value=implied[x];return true;}}return false;
}
fn long ppsz_k_sat_trace(long* v,usz length,char* output,usz capacity) @export("ppsz_k_sat_trace") {
 if(v==null||length<2||length>MAX_INPUT||v[0]<3||v[0]>MAX_N||v[1]<0||v[1]>MAX_CLAUSES)return -1;int n=(int)v[0],m=(int)v[1];if(length!=(usz)(2+3*m+2*n))return -1;
 long[MAX_CLAUSES][3] clauses={};for(int i=0;i<m;i++){bool[MAX_N] seen={};for(int j=0;j<3;j++){long lit=v[2+3*i+j];if(lit==0||lit< -n||lit>n)return -1;int x=(int)(lit>0?lit:-lit)-1;if(seen[x])return -1;seen[x]=true;clauses[i][j]=lit;}}
 int start=2+3*m;int[MAX_N] order={},beta={},assigned={},seen_var={};for(int i=0;i<MAX_N;i++)assigned[i]=-1;
 for(int i=0;i<n;i++){long x=v[start+i];if(x<0||x>=n||seen_var[(int)x])return -1;order[i]=(int)x;seen_var[(int)x]=1;}
 for(int i=0;i<n;i++){long bit=v[start+n+i];if(bit!=0&&bit!=1)return -1;beta[i]=(int)bit;}
 for(int step=0;step<n;step++){int forced,bit;while(find_force(n,m,clauses,assigned,&forced,&bit))assigned[forced]=bit;int x=order[step];if(assigned[x]<0)assigned[x]=beta[x];}
 int mask=0;for(int i=0;i<n;i++)if(assigned[i]==1)mask|=1<<i;long verdict=selected_true(clauses,m,(1<<m)-1,mask)?1:0;
 usz bytes=(usz)(8*(n+1));if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged={};put_i64(staged,0,verdict);for(int i=0;i<n;i++)put_i64(staged,(usz)(8*(i+1)),assigned[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
