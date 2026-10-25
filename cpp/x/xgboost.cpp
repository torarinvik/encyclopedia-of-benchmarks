/* SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt. */
#include <cstddef>
#include <cstdint>
static const uint8_t feature[18]={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
static const uint8_t threshold[18]={100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180};
static const uint8_t left_child[18]={1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130};
static const uint8_t right_child[18]={2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131};
static const uint8_t leaf_value[24]={1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0};
extern "C" int64_t xgboost(const int64_t *v,size_t n){if(n!=64)return -1;for(size_t i=0;i<n;i++)if(v[i]<0||v[i]>255)return -1;uint16_t votes[3]={0,0,0};for(size_t tr=0;tr<6;tr++){size_t base=tr*3;uint8_t node=0;while(!(node&128)){size_t at=base+node;if(v[feature[at]]<threshold[at])node=left_child[at];else node=right_child[at];}votes[tr/2]+=leaf_value[tr*4+(node&127)];}int best=0;for(int c=1;c<3;c++)if(votes[c]>votes[best])best=c;return best;}
