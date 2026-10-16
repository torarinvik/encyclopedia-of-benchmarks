#include <stddef.h>
#include <stdint.h>
int64_t pattern_matching(const int64_t*v,size_t n){if(!v||n<3||n>130||v[0]<0||v[0]>64)return -1;size_t t=(size_t)v[0],pp=t+1;if(n<pp+1||v[pp]<1||v[pp]>64)return -1;size_t p=(size_t)v[pp];if(n!=pp+p+1||p>t)return -1;for(size_t i=0;i<t;i++)if(v[i+1]<0||v[i+1]>127)return -1;for(size_t j=0;j<p;j++)if(v[pp+1+j]<0||v[pp+1+j]>127)return -1;for(size_t i=0;i<=t-p;i++){size_t j=0;for(;j<p;j++)if(v[i+1+j]!=v[pp+1+j])break;if(j==p)return (int64_t)i;}return -1;}
