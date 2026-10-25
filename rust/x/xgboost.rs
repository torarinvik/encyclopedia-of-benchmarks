// SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
const FEATURE:[usize;18]=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];
const THRESHOLD:[i64;18]=[100,100,100,128,120,110,90,140,80,110,100,200,150,150,150,70,130,180];
const LEFT:[u8;18]=[1,128,130,1,128,130,1,128,130,1,128,130,1,128,130,1,128,130];
const RIGHT:[u8;18]=[2,129,131,2,129,131,2,129,131,2,129,131,2,129,131,2,129,131];
const LEAVES:[u8;24]=[1,0,0,2,0,2,1,0,0,1,2,0,1,0,0,2,2,0,1,0,0,2,1,0];
#[no_mangle] pub extern "C" fn xgboost(raw:*const i64,n:usize)->i64{if n!=64{return -1}let v=unsafe{std::slice::from_raw_parts(raw,n)};if v.iter().any(|&x|!(0..=255).contains(&x)){return -1}let mut votes=[0u16;3];for tr in 0..6{let base=tr*3;let mut node=0u8;while node&128==0{let at=base+node as usize;node=if v[FEATURE[at]]<THRESHOLD[at]{LEFT[at]}else{RIGHT[at]};}votes[tr/2]+=LEAVES[tr*4+(node&127) as usize] as u16;}let mut best=0;for c in 1..3{if votes[c]>votes[best]{best=c}}best as i64}
