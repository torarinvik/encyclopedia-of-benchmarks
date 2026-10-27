module random_3sat_greedy_dpll;
const int MAX_VARS=12;const int MAX_CLAUSES=32;const int MAX_INPUT=98;const int MAX_OUTPUT=104;
fn void put_i64(char*out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++){out[at+i]=(char)(b&255);b>>=8;}}
fn long random_3sat_greedy_dpll(long*a,usz n,char*out,usz cap) @export("random_3sat_greedy_dpll"){
 if(a==null||n<(usz)2||n>(usz)MAX_INPUT||a[0]<3||a[0]>MAX_VARS||a[1]<0||a[1]>MAX_CLAUSES)return -1;int nv=(int)a[0],m=(int)a[1];if(n!=(usz)(2+3*m))return -1;
 int[MAX_CLAUSES][3] clauses=zeroed;int[MAX_CLAUSES] lengths=zeroed;bool[MAX_CLAUSES] active=zeroed;
 for(int i=0;i<m;i++){bool[MAX_VARS] seen=zeroed;for(int j=0;j<3;j++){long x=a[2+3*i+j];if(x==0||x< -nv||x>nv)return -1;int v=(int)(x>0?x:-x)-1;if(seen[v])return -1;seen[v]=true;clauses[i][j]=(int)x;}lengths[i]=3;active[i]=true;}
 int[MAX_VARS] assigned=zeroed;bool success=false,failed=false;
 for(int step=0;step<nv&&!failed;step++){int remaining=0;for(int i=0;i<m;i++)if(active[i])remaining++;if(remaining==0){success=true;break;}int chosen=0;for(int i=0;i<m&&chosen==0;i++)if(active[i]&&lengths[i]==1)chosen=clauses[i][0];
  if(chosen==0){int[2*MAX_VARS] counts=zeroed;for(int i=0;i<m;i++)if(active[i])for(int j=0;j<lengths[i];j++){int lit=clauses[i][j],v=(lit>0?lit:-lit)-1;counts[2*v+(lit<0)]++;}int best_count=0;for(int v=0;v<nv;v++)for(int sign=0;sign<2;sign++){int lit=sign?-(v+1):(v+1),cnt=counts[2*v+sign];if(cnt>best_count){chosen=lit;best_count=cnt;}}}
  if(chosen==0){failed=true;break;}int variable=(chosen>0?chosen:-chosen)-1;assigned[variable]=chosen>0?1:-1;
  for(int i=0;i<m;i++)if(active[i]){bool satisfied=false;for(int j=0;j<lengths[i];j++)if(clauses[i][j]==chosen)satisfied=true;if(satisfied){active[i]=false;continue;}int w=0;for(int j=0;j<lengths[i];j++)if(clauses[i][j]!=-chosen){clauses[i][w]=clauses[i][j];w++;}lengths[i]=w;if(w==0){failed=true;break;}}
 }
 if(!failed){int remaining=0;for(int i=0;i<m;i++)if(active[i])remaining++;success=remaining==0;}if(success)for(int i=0;i<nv;i++)if(assigned[i]==0)assigned[i]=-1;
 usz bytes=(usz)(8*(nv+1));if(out==null||cap<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,success?1:0);for(int i=0;i<nv;i++)put_i64(&staged[0],(usz)(8*(i+1)),assigned[i]);for(usz i=0;i<bytes;i++)out[i]=staged[i];return (long)bytes;
}
