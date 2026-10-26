/* Clean-room TSVC s119 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_SIDE=8, MAX_CELLS=64, MAX_INPUT_LENGTH=130 };
static void put64(uint8_t *o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255u);b>>=8;}}
int64_t tsvc_s119_diagonal_matrix_recurrence(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<10||len>MAX_INPUT_LENGTH)return -1;
 if(in[0]<2||in[0]>MAX_SIDE||in[1]<1||in[1]>4)return -1;
 size_t n=(size_t)in[0],passes=(size_t)in[1],cells=n*n;if(len!=2+2*cells)return -1;
 int64_t a[MAX_CELLS],b[MAX_CELLS];for(size_t i=0;i<cells;++i){int64_t av=in[2+i],bv=in[2+cells+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=av;b[i]=bv;}
 size_t bytes=8*cells;if(!out||cap<bytes)return -2;
 for(size_t p=0;p<passes;++p)for(size_t i=1;i<n;++i)for(size_t j=1;j<n;++j)a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j];
 for(size_t i=0;i<cells;++i)put64(out,8*i,a[i]);return (int64_t)cells;
}
