#include <stddef.h>
#include <stdint.h>
int64_t neural_network_perceptron_classifier(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<5)return -1;int f=(int)v[0],s=(int)v[1];int64_t bias=v[2];if(f<1||f>3||s<1||s>4||bias < -10000||bias>10000||n!=3+(size_t)f+(size_t)f*s)return -1;for(int i=0;i<f;i++)if(v[3+i]<-10000||v[3+i]>10000)return -1;for(size_t i=3+(size_t)f;i<n;i++)if(v[i]<-10||v[i]>10)return -1;if(!out||cap<(size_t)s)return -2;for(int j=0;j<s;j++){int64_t z=bias;for(int i=0;i<f;i++)z+=v[3+i]*v[3+f+(size_t)i*s+j];out[j]=(uint8_t)(z>0);}return s;}
