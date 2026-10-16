#include <stddef.h>
#include <stdint.h>
int64_t two_pointer(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 258) return -2;
    int64_t n=input[0],target=input[1];if(n<0||n>256||length!=(size_t)n+2||target<INT32_MIN||target>INT32_MAX)return -2;
    for(size_t i=0;i<(size_t)n;i++)if(input[i+2]<INT32_MIN||input[i+2]>INT32_MAX||(i&&input[i+1]>input[i+2]))return -2;
    size_t left=0,right=(size_t)n; if(right>0)--right;
    while(left<right){int64_t sum=input[left+2]+input[right+2];if(sum==target)return (int64_t)(left*256+right);if(sum<target)++left;else --right;}
    return -1;
}
