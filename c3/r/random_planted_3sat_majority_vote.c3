module random_planted_3sat_majority_vote;
const int MAX_VARS=12; const int MAX_CLAUSES=32; const int MAX_INPUT=98; const int MAX_OUTPUT=96;
fn void put_i64(char *out, usz at, long value) { ulong bits=(ulong)value; for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;} }
fn long random_planted_3sat_majority_vote(long *input, usz length, char *output, usz capacity) @export("random_planted_3sat_majority_vote") {
 if(input==null||length<(usz)2||length>(usz)MAX_INPUT||input[0]<3||input[0]>MAX_VARS||input[1]<0||input[1]>MAX_CLAUSES)return -1;
 int n=(int)input[0],m=(int)input[1];if(length!=(usz)(2+3*m))return -1;
 int[MAX_VARS] positive=zeroed,negative=zeroed;
 for(int c=0;c<m;c++){bool[MAX_VARS] seen=zeroed;for(int j=0;j<3;j++){long raw=input[2+3*c+j];if(raw==0||raw<-(long)n||raw>(long)n)return -1;int lit=(int)raw,v=(lit>0?lit:-lit)-1;if(seen[v])return -1;seen[v]=true;if(lit>0)positive[v]++;else negative[v]++;}}
 usz bytes=(usz)(8*n);if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;
 for(int v=0;v<n;v++)put_i64(&staged[0],(usz)(8*v),positive[v]>negative[v]?1:-1);
 for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
