// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
package slre
import "core:c"
atom :: proc(x:i64)->bool{return (x>=97&&x<=122)||x==i64('.')}
@(export)
slre :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
 if n<2 do return -2
 if v[0]<0||v[0]>24||v[1]<1||v[1]>24 do return -2
 t:=c.size_t(v[0]);p:=c.size_t(v[1]);ps:=2+t;if n!=ps+p do return -2
 for i:c.size_t=0;i<t;i+=1{if v[2+i]<97||v[2+i]>122 do return -2}
 lo:c.size_t=0;hi:=p;ast:=false;aend:=false;if v[ps]==i64('^'){ast=true;lo+=1};if lo<hi&&v[ps+hi-1]==i64('$'){aend=true;hi-=1}
 i:=lo;non:=false;for i<hi{x:=v[ps+i];if x==i64('|'){if !non do return -2;non=false;i+=1;continue};if !atom(x)do return -2;non=true;i+=1;if i<hi&&v[ps+i]==i64('?'){i+=1}};if !non do return -2
 for start:c.size_t=0;start<=t;start+=1{if ast&&start>0 do break;b:=lo;for b<=hi{e:=b;for e<hi&&v[ps+e]!=i64('|'){e+=1;if e<hi&&v[ps+e]==i64('?'){e+=1}};q:=b;pos:=start;ok:=true;for q<e{x:=v[ps+q];opt:=q+1<e&&v[ps+q+1]==i64('?');if pos<t&&(x==i64('.')||x==v[2+pos]){pos+=1}else if !opt{ok=false;break};if opt{q+=2}else{q+=1}};if ok&&(!aend||pos==t){return i64(pos)};if e==hi do break;b=e+1}}
 return -1
}
