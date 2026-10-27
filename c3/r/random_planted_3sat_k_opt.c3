module random_planted_3sat_k_opt;
const int MAX_VARS=12; const int MAX_CLAUSES=32; const int MAX_INPUT=98; const int MAX_OUTPUT=104;
fn void put_i64(char *out, usz at, long value) { ulong bits=(ulong)value; for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;} }
fn uint sat_set(int *clauses,int m,int n,ulong code){uint set=0;for(int c=0;c<m;c++){bool satisfied=false;for(int j=0;j<3;j++){int lit=clauses[3*c+j],v=(lit>0?lit:-lit)-1;bool truth=((code>>(n-1-v))&1ul)!=0;if(truth==(lit>0))satisfied=true;}if(satisfied)set|=(uint)1<<c;}return set;}
fn long random_planted_3sat_k_opt(long *input, usz length, char *output, usz capacity) @export("random_planted_3sat_k_opt") {
 if(input==null||length<(usz)2||length>(usz)MAX_INPUT||input[0]<3||input[0]>MAX_VARS||input[1]<0||input[1]>MAX_CLAUSES)return -1;
 int n=(int)input[0],m=(int)input[1];if(length!=(usz)(2+3*m))return -1;
 int[MAX_CLAUSES*3] clauses=zeroed;int[MAX_VARS] positive=zeroed,negative=zeroed;
 for(int c=0;c<m;c++){bool[MAX_VARS] seen=zeroed;for(int j=0;j<3;j++){long raw=input[2+3*c+j];if(raw==0||raw<-(long)n||raw>(long)n)return -1;int lit=(int)raw,v=(lit>0?lit:-lit)-1;if(seen[v])return -1;seen[v]=true;clauses[3*c+j]=lit;if(lit>0)positive[v]++;else negative[v]++;}}
 ulong current=0;for(int v=0;v<n;v++)if(positive[v]>negative[v])current|=1ul<<(n-1-v);
 uint full=m==32?0xffffffffu:(m==0?0u:(((uint)1<<m)-1u));int status=0,k=1;
 while(true){uint before=sat_set(&clauses[0],m,n,current);if(before==full){status=1;break;}bool found=false;ulong limit=1ul<<n;
  for(ulong candidate=0;candidate<limit;candidate++){ulong diff=current^candidate;int distance=0;while(diff!=0){diff&=diff-1;distance++;}if(distance==0||distance>k)continue;uint after=sat_set(&clauses[0],m,n,candidate);if(after!=before&&(after&before)==before){current=candidate;found=true;break;}}
  if(found)continue;if(k==n){status=0;break;}k++;
 }
 usz bytes=(usz)(8*(n+1));if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,status);
 for(int v=0;v<n;v++)put_i64(&staged[0],(usz)(8*(v+1)),((current>>(n-1-v))&1ul)!=0?1:-1);
 for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
