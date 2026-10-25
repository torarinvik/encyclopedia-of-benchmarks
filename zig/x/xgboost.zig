// SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
const feature=[_]usize{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
const threshold=[_]i64{100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180};
const left=[_]u8{1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130};
const right=[_]u8{2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131};
const leaves=[_]u8{1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0};
export fn xgboost(raw:[*]const i64,n:usize)i64{if(n!=64)return -1;const v=raw[0..n];for(v)|x|{if(x<0 or x>255)return -1;}var votes=[_]u16{0,0,0};for(0..6)|tr|{const base=tr*3;var node:u8=0;while((node&128)==0){const at=base+@as(usize,node);node=if(v[feature[at]]<threshold[at]) left[at] else right[at];}votes[tr/2]+=@as(u16,leaves[tr*4+@as(usize,node&127)]);}var best:usize=0;for(1..3)|c|{if(votes[c]>votes[best])best=c;}return @intCast(best);}
