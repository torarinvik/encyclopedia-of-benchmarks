/* SPDX-License-Identifier: GPL-3.0-or-later
 * Bounded modified profile of Embench slre; upstream credits Sergey Lyubka,
 * Cesanta Software Limited, Embecosm Limited, University of Bristol;
 * contributors James Pallister and Jeremy Bennett. See package NOTICE.txt. */
/* Bounded source-compatible slre search profile. */
#include <stddef.h>
#include <stdint.h>
static int atom(int64_t x){return (x>='a'&&x<='z')||x=='.';}
int64_t slre(const int64_t *v,size_t n){
 if(n<2||v[0]<0||v[0]>24||v[1]<1||v[1]>24)return -2;
 size_t t=(size_t)v[0],p=(size_t)v[1],ps=2+t;if(n!=2+t+p)return -2;
 for(size_t i=0;i<t;i++)if(v[2+i]<'a'||v[2+i]>'z')return -2;
 size_t lo=0,hi=p;int ast=0,aend=0;
 if(v[ps]=='^'){ast=1;lo++;} if(lo<hi&&v[ps+hi-1]=='$'){aend=1;hi--;}
 size_t i=lo;int branch_nonempty=0;
 while(i<hi){int64_t x=v[ps+i];if(x=='|'){if(!branch_nonempty)return -2;branch_nonempty=0;i++;continue;}if(!atom(x))return -2;branch_nonempty=1;i++;if(i<hi&&v[ps+i]=='?')i++;}
 if(!branch_nonempty)return -2;
 for(size_t start=0;start<=t;start++){if(ast&&start)break;size_t b=lo;
  while(b<=hi){size_t e=b;while(e<hi&&v[ps+e]!='|'){e++;if(e<hi&&v[ps+e]=='?')e++;}
   size_t q=b,pos=start;int ok=1;while(q<e){int64_t x=v[ps+q];int opt=q+1<e&&v[ps+q+1]=='?';if(pos<t&&(x=='.'||x==v[2+pos]))pos++;else if(!opt){ok=0;break;}q+=opt?2:1;}
   if(ok&&(!aend||pos==t))return (int64_t)pos;
   if(e==hi)break;b=e+1;
  }
 }
 return -1;
}
