# SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
const Feature: array[18,int] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]
const Threshold: array[18,int64] = [100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180]
const LeftChild: array[18,int] = [1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130]
const RightChild: array[18,int] = [2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131]
const Leaves: array[24,int64] = [1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0]
proc xgboost*(values: ptr UncheckedArray[int64], length:csize_t):int64 {.cdecl,exportc:"xgboost".}=
 if length!=64:return -1
 for i in 0..<64:
  if values[i]<0 or values[i]>255:return -1
 var votes:array[3,int64]
 for tr in 0..<6:
  let base=tr*3
  var node=0
  while node<128:
   let at=base+node
   if values[Feature[at]]<Threshold[at]:node=LeftChild[at] else:node=RightChild[at]
  votes[tr div 2]+=Leaves[tr*4+(node and 127)]
 var best=0
 for c in 1..<3:
  if votes[c]>votes[best]:best=c
 return int64(best)
