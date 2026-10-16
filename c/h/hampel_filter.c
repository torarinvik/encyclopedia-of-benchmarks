/* Three-sample Java Hampel filter; emit integral filtered samples as LE i64. */
#include <stddef.h>
#include <stdint.h>
#define MAX_N 128
#define WINDOW 3
#define MAX_VALUE 1000
static void insert_sorted(double *a, size_t *size, double value) {
    size_t pos=0; while (pos<*size && a[pos]<value) ++pos;
    for (size_t j=*size;j>pos;--j) a[j]=a[j-1];
    a[pos]=value; ++*size;
}
static void remove_sorted(double *a, size_t *size, double value) {
    size_t pos=0; while (pos<*size && a[pos]!=value) ++pos;
    if (pos==*size) return;
    for (size_t j=pos+1;j<*size;++j) a[j-1]=a[j];
    --*size;
}
static double median(const double *a, size_t size) {
    size_t middle=size/2;
    return size%2 ? a[middle] : 0.5*(a[middle-1]+a[middle]);
}
static double mad(const double *sorted, size_t size, double med) {
    size_t split=0; while (split<size && sorted[split]<=med) ++split;
    int left=(int)split-1; size_t right=split;
    double deviations[WINDOW];
    for (size_t i=0;i<size;++i) {
        int take_left=right>=size || (left>=0 && med-sorted[left] <= sorted[right]-med);
        if (take_left) { deviations[i]=med-sorted[left]; --left; }
        else { deviations[i]=sorted[right]-med; ++right; }
    }
    return size%2 ? deviations[size/2] : 0.5*(deviations[size/2-1]+deviations[size/2]);
}
static void put_i64_le(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[at+b]=(uint8_t)(bits>>(8*b));}
int64_t hampel_filter(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<1||input[0]<0||input[0]>MAX_N||length!=(size_t)input[0]+1)return -1;
    size_t n=(size_t)input[0];for(size_t i=0;i<n;++i)if(input[i+1]<-MAX_VALUE||input[i+1]>MAX_VALUE)return -1;
    if(capacity<n*8||(n>0&&!output))return -2;
    double arrival[WINDOW]={0}, sorted[WINDOW]={0};size_t size=0,oldest=0;
    for(size_t i=0;i<n;++i){double value=(double)input[i+1];if(size==WINDOW){remove_sorted(sorted,&size,arrival[oldest]);}
        insert_sorted(sorted,&size,value);arrival[oldest]=value;oldest=(oldest+1)%WINDOW;
        double med=median(sorted,size);double mdev=mad(sorted,size,med);
        double scaled=3.0*1.4826*mdev;double filtered=(value-med>0?value-med:med-value)>scaled?med:value;
        put_i64_le(output,i*8,(int64_t)filtered);
    }
    return (int64_t)(n*8);
}
