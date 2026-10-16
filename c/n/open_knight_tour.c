#include <stddef.h>
#include <stdint.h>
static const int dr[8]={1,-1,1,-1,2,2,-2,-2},dc[8]={2,2,-2,-2,1,-1,1,-1};
static int search(int b[25],int n,int r,int c,int step){if(step==n*n)return 1;for(int k=0;k<8;k++){int nr=r+dr[k],nc=c+dc[k];if(nr>=0&&nr<n&&nc>=0&&nc<n&&b[nr*n+nc]==0){b[nr*n+nc]=step+1;if(search(b,n,nr,nc,step+1))return 1;b[nr*n+nc]=0;}}return 0;}
static void put(uint8_t*out,size_t off,int32_t x){uint32_t b=(uint32_t)x;for(int k=0;k<4;k++)out[off+k]=(uint8_t)(b>>(8*k));}
int64_t open_knight_tour(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=1||v[0]<1||v[0]>5)return -1;int d=(int)v[0],b[25]={0};if(!out||cap<(size_t)d*d*4)return -2;for(int r=0;r<d;r++)for(int c=0;c<d;c++){b[r*d+c]=1;if(search(b,d,r,c,1))goto done;b[r*d+c]=0;}done:for(int i=0;i<d*d;i++)put(out,(size_t)i*4,b[i]);return (int64_t)d*d*4;}
