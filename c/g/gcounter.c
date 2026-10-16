#include <stddef.h>
#include <stdint.h>
#define MAXOPS 128
static uint64_t hv(uint64_t h,int64_t v){uint64_t x=(uint64_t)v;for(int i=0;i<8;i++)h=(h^((x>>(8*i))&255))*UINT64_C(0x100000001b3);return h;}
int64_t gcounter(const int64_t*a,size_t n){
 if(!a||n<2||n>386||a[0]<1||a[0]>8||a[1]<0||a[1]>MAXOPS||n!=2+3*(size_t)a[1])return -1;
 int nodes=(int)a[0];int64_t s[8][8]={{0}};uint64_t h=UINT64_C(0xcbf29ce484222325);
 for(int i=0;i<a[1];i++){int64_t op=a[2+3*i],aa=a[3+3*i],bb=a[4+3*i];if(aa<0||aa>=nodes)return -1;
 if(op==0){if(bb!=0||s[aa][aa]>=1000000)return -1;s[aa][aa]++;}
 else if(op==1){if(bb!=0)return -1;int64_t total=0;for(int j=0;j<nodes;j++)total+=s[aa][j];h=hv(h,total);}
 else if(op==2){if(bb<0||bb>=nodes)return -1;int yes=1;for(int j=0;j<nodes;j++)if(s[aa][j]>s[bb][j])yes=0;h=hv(h,yes);}
 else if(op==3){if(bb<0||bb>=nodes)return -1;for(int j=0;j<nodes;j++)if(s[bb][j]>s[aa][j])s[aa][j]=s[bb][j];}
 else return -1;
 }
 for(int i=0;i<nodes;i++)for(int j=0;j<nodes;j++)h=hv(h,s[i][j]);return (int64_t)h;
}
