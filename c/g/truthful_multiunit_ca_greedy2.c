#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_ITEMS = 6, MAX_BIDDERS = 12, MAX_INPUT = 32, MAX_OUTPUT = 104 };
static void put_i64(uint8_t *out, size_t at, int64_t x) { uint64_t b=(uint64_t)x; for(size_t i=0;i<8;i++){out[at+i]=(uint8_t)(b&255);b>>=8;} }

int64_t truthful_multiunit_ca_greedy2(const int64_t *a, size_t n, uint8_t *out, size_t cap) {
    if(!a||n<5||n>MAX_INPUT||a[0]<2||a[0]>MAX_ITEMS||a[1]<1||a[1]>MAX_BIDDERS)return -1;
    int r=(int)a[0],k=(int)a[1]; if(n!=(size_t)(2+r+2*k))return -1;
    int b[MAX_ITEMS],B=100; double y[MAX_ITEMS];
    for(int e=0;e<r;e++){if(a[2+e]<1||a[2+e]>8)return -1;b[e]=(int)a[2+e];if(b[e]<B)B=b[e];y[e]=1.0/(double)b[e];}
    int value[MAX_BIDDERS],mask[MAX_BIDDERS];
    for(int i=0;i<k;i++){int64_t v=a[2+r+2*i],m=a[3+r+2*i];if(v<1||v>100||m<1||m>=(1<<r))return -1;value[i]=(int)v;mask[i]=(int)m;}
    const double threshold=pow(2.718281828459045,(double)B)*(double)r;
    int chosen[MAX_BIDDERS]={0},order[MAX_BIDDERS],count=0;
    while(count<k){int best=-1;double best_score=-1.0;for(int i=0;i<k;i++)if(!chosen[i]){double den=0.0;for(int e=0;e<r;e++)if(mask[i]&(1<<e))den+=y[e];double score=(double)value[i]/den;if(best<0||score>best_score){best=i;best_score=score;}}
        if(best<0)break;chosen[best]=1;order[count++]=best;
        for(int e=0;e<r;e++)if(mask[best]&(1<<e))y[e]*=pow(threshold,1.0/(double)b[e]);
        double dual=0.0;for(int e=0;e<r;e++)dual+=(double)b[e]*y[e];if(dual>=threshold)break;
    }
    size_t bytes=8*(size_t)(1+count);if(!out||cap<bytes)return -2;uint8_t staged[MAX_OUTPUT];put_i64(staged,0,count);for(int i=0;i<count;i++)put_i64(staged,8*(size_t)(i+1),order[i]);for(size_t i=0;i<bytes;i++)out[i]=staged[i];return (int64_t)bytes;
}
