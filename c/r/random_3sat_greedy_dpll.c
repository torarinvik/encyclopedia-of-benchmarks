#include <stddef.h>
#include <stdint.h>

enum { MAX_VARS=12, MAX_CLAUSES=32, MAX_INPUT=98, MAX_OUTPUT=104 };
static void put_i64(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++){out[at+i]=(uint8_t)(b&255);b>>=8;}}

int64_t random_3sat_greedy_dpll(const int64_t*a,size_t n,uint8_t*out,size_t cap){
 if(!a||n<2||n>MAX_INPUT||a[0]<3||a[0]>MAX_VARS||a[1]<0||a[1]>MAX_CLAUSES)return -1;int nv=(int)a[0],m=(int)a[1];if(n!=(size_t)(2+3*m))return -1;
 int clauses[MAX_CLAUSES][3]={{0}},length[MAX_CLAUSES],active[MAX_CLAUSES]={0};for(int i=0;i<m;i++){int seen[MAX_VARS]={0};for(int j=0;j<3;j++){int64_t x=a[2+3*i+j];if(x==0||x< -nv||x>nv)return -1;int v=(int)(x>0?x:-x)-1;if(seen[v])return -1;seen[v]=1;clauses[i][j]=(int)x;}length[i]=3;active[i]=1;}
 int assigned[MAX_VARS]={0},success=0,failed=0;
 for(int step=0;step<nv&&!failed;step++){
  int remaining=0;for(int i=0;i<m;i++)remaining+=active[i];if(remaining==0){success=1;break;}
  int chosen=0;for(int i=0;i<m&&!chosen;i++)if(active[i]&&length[i]==1)chosen=clauses[i][0];
  if(!chosen){int count[2*MAX_VARS]={0};for(int i=0;i<m;i++)if(active[i])for(int j=0;j<length[i];j++){int lit=clauses[i][j],v=(lit>0?lit:-lit)-1;count[2*v+(lit<0)]++;}int best=0,best_count=0;for(int v=0;v<nv;v++)for(int sign=0;sign<2;sign++){int lit=sign?-(v+1):(v+1),c=count[2*v+sign];if(c>best_count){best=lit;best_count=c;}}chosen=best;}
  if(!chosen){failed=1;break;}int var=(chosen>0?chosen:-chosen)-1;assigned[var]=chosen>0?1:-1;
  for(int i=0;i<m;i++)if(active[i]){int satisfied=0;for(int j=0;j<length[i];j++)if(clauses[i][j]==chosen)satisfied=1;if(satisfied){active[i]=0;continue;}int w=0;for(int j=0;j<length[i];j++)if(clauses[i][j]!=-chosen)clauses[i][w++]=clauses[i][j];length[i]=w;if(w==0){failed=1;break;}}
 }
 if(!failed){int remaining=0;for(int i=0;i<m;i++)remaining+=active[i];if(remaining==0)success=1;}
 if(success)for(int i=0;i<nv;i++)if(assigned[i]==0)assigned[i]=-1;
 size_t bytes=8*(size_t)(nv+1);if(!out||cap<bytes)return -2;uint8_t staged[MAX_OUTPUT];put_i64(staged,0,success);for(int i=0;i<nv;i++)put_i64(staged,8*(size_t)(i+1),assigned[i]);for(size_t i=0;i<bytes;i++)out[i]=staged[i];return (int64_t)bytes;
}
