// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
module slre;
fn bool atom(long x) { return (x >= 'a' && x <= 'z') || x == '.'; }
fn long slre(long* v, usz n) @export("slre") {
 if(n<2||v[0]<0||v[0]>24||v[1]<1||v[1]>24)return -2;
 usz t=(usz)v[0],p=(usz)v[1],ps=2+t;if(n!=ps+p)return -2;
 for(usz i=0;i<t;i++)if(v[2+i]<'a'||v[2+i]>'z')return -2;
 usz lo=0,hi=p;bool ast=false,aend=false;if(v[ps]=='^'){ast=true;lo++;}if(lo<hi&&v[ps+hi-1]=='$'){aend=true;hi--;}
 usz i=lo;bool non=false;while(i<hi){long x=v[ps+i];if(x=='|'){if(!non)return -2;non=false;i++;continue;}if(!atom(x))return -2;non=true;i++;if(i<hi&&v[ps+i]=='?')i++;}if(!non)return -2;
 for(usz start=0;start<=t;start++){if(ast&&start>0)break;usz b=lo;while(b<=hi){usz e=b;while(e<hi&&v[ps+e]!='|'){e++;if(e<hi&&v[ps+e]=='?')e++;}usz q=b,pos=start;bool ok=true;while(q<e){long x=v[ps+q];bool opt=q+1<e&&v[ps+q+1]=='?';if(pos<t&&(x=='.'||x==v[2+pos]))pos++;else if(!opt){ok=false;break;}q+=opt?2:1;}if(ok&&(!aend||pos==t))return (long)pos;if(e==hi)break;b=e+1;}}
 return -1;
}
