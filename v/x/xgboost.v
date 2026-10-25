// SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
module xgboost
const feature = [i64(0),1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]
const threshold = [i64(100),100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180]
const left_child = [i64(1),128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130]
const right_child = [i64(2),129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131]
const leaves = [i64(1),0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0]
@[export: 'xgboost']
pub fn xgboost(values &i64, length usize) i64 {
 if length != 64 { return -1 }
 mut votes := [3]i64{}
 for i in 0 .. length { x := unsafe { values[i] }; if x < 0 || x > 255 { return -1 } }
 for tr in 0 .. 6 { base := tr*3; mut node := i64(0); for (node & 128) == 0 { at := base + usize(node); if unsafe { values[usize(feature[at])] } < threshold[at] { node=left_child[at] } else { node=right_child[at] } }; votes[tr/2] += leaves[tr*4+usize(node&127)] }
 mut best := 0; for c in 1 .. 3 { if votes[c] > votes[best] { best=c } }; return i64(best)
}
