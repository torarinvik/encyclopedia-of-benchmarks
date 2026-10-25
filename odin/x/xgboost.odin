// SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
package xgboost
import "core:c"
FEATURE: [18]u8 = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}
THRESHOLD: [18]i64 = {100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180}
LEFT_CHILD: [18]u8 = {1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130}
RIGHT_CHILD: [18]u8 = {2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131}
LEAVES: [24]u8 = {1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0}
@(export)
xgboost :: proc "c" (values:[^]i64,length:c.size_t)->i64 {
 if length!=64 do return -1
 for i:c.size_t=0;i<length;i+=1{if values[i]<0||values[i]>255 do return -1}
 votes:[3]u16={0,0,0}
 for tr:c.size_t=0;tr<6;tr+=1{base:=tr*3;node:u8=0;for (node & 128) == 0 {at:=base+c.size_t(node);if values[FEATURE[at]]<THRESHOLD[at]{node=LEFT_CHILD[at]}else{node=RIGHT_CHILD[at]}};votes[tr/2]+=u16(LEAVES[tr*4+c.size_t(node&127)])}
 best:=0;for cidx:=1;cidx<3;cidx+=1{if votes[cidx]>votes[best]{best=cidx}};return i64(best)
}
