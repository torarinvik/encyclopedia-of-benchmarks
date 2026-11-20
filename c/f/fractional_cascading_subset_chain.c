#include <stddef.h>
#include <stdint.h>

enum { MIN_M=2, MAX_M=8, MAX_Q=8, MAX_N=16, MAX_LEN=147, NO_SUCCESSOR=34 };

int64_t fractional_cascading_subset_chain(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LEN) return -1;
    const int64_t raw_m=input[0], raw_q=input[1];
    if (raw_m<MIN_M || raw_m>MAX_M || raw_q<1 || raw_q>MAX_Q) return -1;
    const int m=(int)raw_m, q=(int)raw_q;
    int64_t catalog[MAX_M][MAX_N]={{0}}, query[MAX_Q]={0};
    int sizes[MAX_M]={0}; size_t cursor=2;
    for (int i=0;i<m;i++) {
        if (cursor>=length) return -1;
        const int64_t raw_size=input[cursor++];
        if (raw_size<1 || raw_size>MAX_N || cursor+(size_t)raw_size>length) return -1;
        const int n=(int)raw_size; sizes[i]=n;
        for (int j=0;j<n;j++) {
            const int64_t value=input[cursor++];
            if (value < -16 || value > 16) return -1;
            if (j>0 && catalog[i][j-1]>=value) return -1;
            catalog[i][j]=value;
        }
        if (i>0) {
            int a=0,b=0;
            while (a<sizes[i-1] && b<n) {
                if (catalog[i-1][a]<catalog[i][b]) a++;
                else if (catalog[i-1][a]==catalog[i][b]) { a++; b++; }
                else return -1;
            }
            if (b!=n) return -1;
        }
    }
    if (cursor+(size_t)q!=length) return -1;
    for (int i=0;i<q;i++) { query[i]=input[cursor++]; if(query[i] < -17 || query[i]>17)return -1; }

    int bridge[MAX_M-1][MAX_N+1]={{0}};
    for (int i=0;i<m-1;i++) {
        int child=0;
        for (int slot=0;slot<sizes[i];slot++) {
            while(child<sizes[i+1] && catalog[i+1][child]<catalog[i][slot]) child++;
            bridge[i][slot]=child;
        }
        bridge[i][sizes[i]]=sizes[i+1];
    }
    int64_t checksum=0;
    for (int qi=0;qi<q;qi++) {
        int low=0,high=sizes[0];
        while(low<high){int mid=(low+high)/2;if(catalog[0][mid]<query[qi])low=mid+1;else high=mid;}
        int slot=low;
        for(int ci=0;ci<m;ci++){
            const int64_t code=slot<sizes[ci]?catalog[ci][slot]+17:NO_SUCCESSOR;
            checksum+=(int64_t)(qi+1)*(ci+1)*code;
            if(ci+1<m)slot=bridge[ci][slot];
        }
    }
    return checksum;
}
