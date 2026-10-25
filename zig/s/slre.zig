// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
fn atom(x:i64)bool{return (x>='a' and x<='z') or x=='.';}
export fn slre(raw:[*]const i64,n:usize)i64{
 if(n<2)return -2;const v=raw[0..n];if(v[0]<0 or v[0]>24 or v[1]<1 or v[1]>24)return -2;const t:usize=@intCast(v[0]);const p:usize=@intCast(v[1]);const ps=2+t;if(n!=ps+p)return -2;for(v[2..ps])|x|{if(x<'a' or x>'z')return -2;}
 var lo:usize=0;var hi=p;var ast=false;var aend=false;if(v[ps]=='^'){ast=true;lo+=1;}if(lo<hi and v[ps+hi-1]=='$'){aend=true;hi-=1;}
 var i=lo;var non=false;while(i<hi){const x=v[ps+i];if(x=='|'){if(!non)return -2;non=false;i+=1;continue;}if(!atom(x))return -2;non=true;i+=1;if(i<hi and v[ps+i]=='?')i+=1;}if(!non)return -2;
 var start:usize=0;while(start<=t):(start+=1){if(ast and start>0)break;var b=lo;while(b<=hi){var e=b;while(e<hi and v[ps+e]!='|'):(e+=1){if(e+1<hi and v[ps+e+1]=='?')e+=1;}var q=b;var pos=start;var ok=true;while(q<e){const x=v[ps+q];const opt=q+1<e and v[ps+q+1]=='?';if(pos<t and (x=='.' or x==v[2+pos]))pos+=1 else if(!opt){ok=false;break;}q+=if(opt) @as(usize,2) else 1;}if(ok and (!aend or pos==t))return @intCast(pos);if(e==hi)break;b=e+1;}}
 return -1;
}
