#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
double half_wave_rectifier(const int64_t *a,size_t n){if(!a||n!=5)return INVALID_RESULT;for(size_t i=1;i<5;i++)if(a[i]<-1000000||a[i]>1000000)return INVALID_RESULT;switch(a[0]){case 0:if(a[1]<0||a[2]<0||a[3]<0||(a[1]==0&&a[2]==0&&a[3]==0))return INVALID_RESULT;return (double)a[4]/(double)(a[1]+a[2]+a[3]);case 1:if(a[2]||a[3]||a[4])return INVALID_RESULT;return (double)a[1]*0.318;case 2:if(a[2]||a[3]||a[4])return INVALID_RESULT;return (double)a[1]*0.318;case 3:if(a[2]<=0||a[3]||a[4])return INVALID_RESULT;return (double)a[1]/(double)a[2];case 4:if(a[2]||a[3]||a[4])return INVALID_RESULT;return (double)a[1]/2.0;case 5:if(a[2]||a[3]||a[4])return INVALID_RESULT;return (double)a[1]/2.0;default:return INVALID_RESULT;}}
