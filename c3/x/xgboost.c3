// SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
module xgboost;
const long[18] FEATURE={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
const long[18] THRESHOLD={100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180};
const long[18] LEFT={1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130};
const long[18] RIGHT={2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131};
const long[24] LEAVES={1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0};
fn long xgboost(long* v,usz n) @export("xgboost") {if(n!=64)return -1;for(usz i=0;i<n;i++)if(v[i]<0||v[i]>255)return -1;long[3] votes={0,0,0};for(usz tr=0;tr<6;tr++){usz base=tr*3;long node=0;while((node&128)==0){usz at=base+(usz)node;node=v[FEATURE[at]]<THRESHOLD[at]?LEFT[at]:RIGHT[at];}votes[tr/2]+=LEAVES[tr*4+(usz)(node&127)];}long best=0;for(usz c=1;c<3;c++)if(votes[c]>votes[best])best=(long)c;return best;}
