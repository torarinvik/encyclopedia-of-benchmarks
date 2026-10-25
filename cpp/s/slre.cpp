/* SPDX-License-Identifier: GPL-3.0-or-later
 * Bounded modified profile of Embench slre. See package NOTICE.txt for
 * upstream copyright and contributor attribution. */
#include <cstddef>
#include <cstdint>
static bool atom(int64_t x){return (x>='a'&&x<='z')||x=='.';}
extern "C" int64_t slre(const int64_t *v,size_t n){
 if(n<2||v[0]<0||v[0]>24||v[1]<1||v[1]>24)return -2;size_t t=v[0],p=v[1],ps=2+t;if(n!=2+t+p)return -2;
 for(size_t i=0;i<t;i++)if(v[2+i]<'a'||v[2+i]>'z')return -2;size_t lo=0,hi=p;bool ast=false,aend=false;
 if(v[ps]=='^'){ast=true;lo++;}if(lo<hi&&v[ps+hi-1]=='$'){aend=true;hi--;}
 size_t i=lo;bool non=false;while(i<hi){auto x=v[ps+i];if(x=='|'){if(!non)return -2;non=false;i++;continue;}if(!atom(x))return -2;non=true;i++;if(i<hi&&v[ps+i]=='?')i++;}if(!non)return -2;
 for(size_t start=0;start<=t;start++){if(ast&&start)break;size_t b=lo;while(b<=hi){size_t e=b;while(e<hi&&v[ps+e]!='|'){e++;if(e<hi&&v[ps+e]=='?')e++;}size_t q=b,pos=start;bool ok=true;while(q<e){auto x=v[ps+q];bool opt=q+1<e&&v[ps+q+1]=='?';if(pos<t&&(x=='.'||x==v[2+pos]))pos++;else if(!opt){ok=false;break;}q+=opt?2:1;}if(ok&&(!aend||pos==t))return pos;if(e==hi)break;b=e+1;}}
 return -1;
}
