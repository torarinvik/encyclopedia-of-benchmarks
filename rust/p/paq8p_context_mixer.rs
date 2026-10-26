// Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
// This program is free software; you can redistribute and/or modify it under
// the GNU General Public License as published by the Free Software Foundation;
// either version 2 of the License, or (at your option) any later version.
// It is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See https://www.gnu.org/licenses/ for details.
const ST: [i32;33]=[1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094];
fn squash(mut d:i32)->i32{if d>2047{return 4095}if d< -2047{return 0}let w=d&127;d=(d>>7)+16;(ST[d as usize]*(128-w)+ST[d as usize+1]*w+64)>>7}
fn make_stretch()->[i32;4096]{let mut t=[0;4096];let mut pi=0;for x in -2047..=2047{let end=squash(x);for j in pi..=end{t[j as usize]=x;}pi=end+1;}t[4095]=2047;t}
fn dot8(t:&[i32;8],w:&[i32;8])->i32{let mut sum=0;for i in (0..8).step_by(2){sum+=(t[i]*w[i]+t[i+1]*w[i+1])>>8;}sum}
fn train8(t:&[i32;8],w:&mut[i32;8],err:i32){for i in 0..8{let value=w[i]+(((t[i]*err*2>>16)+1)>>1);w[i]=value.clamp(-32768,32767);}}
#[no_mangle]
pub unsafe extern "C" fn paq8p_context_mixer(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||!(12..=177).contains(&length){return -1}let n=*input;if !(1..=16).contains(&n)||length!=1+n as usize*11{return -1}
 let mut features=[[0i32;8];16];let mut c0=[0usize;16];let mut c1=[0usize;16];let mut target=[0i32;16];let mut p=1usize;
 for s in 0..n as usize{let a=*input.add(p);let b=*input.add(p+1);let y=*input.add(p+2);if !(0..=1).contains(&a)||!(0..=1).contains(&b)||!(0..=1).contains(&y){return -1}c0[s]=a as usize;c1[s]=b as usize;target[s]=y as i32;p+=3;for j in 0..8{let v=*input.add(p);if !(-2047..=2047).contains(&v){return -1}features[s][j]=v as i32;p+=1;}}
 let needed=n as usize*2;if output.is_null()||capacity<needed{return -2}let stretch=make_stretch();let mut outer=[[0i32;8];4];let mut inner=[32767i32;8];let mut prev_inner=[0i32;8];let mut prev_prediction=2048;let mut prev_target=0;
 for s in 0..n as usize{if s>0{train8(&prev_inner,&mut inner,((prev_target<<12)-prev_prediction)*7);}let contexts=[c0[s],2+c1[s]];let mut model=[0;2];for k in 0..2{model[k]=squash(dot8(&features[s],&outer[contexts[k]])>>5);}let x=[stretch[model[0] as usize],stretch[model[1] as usize],0,0,0,0,0,0];let prediction=squash(dot8(&x,&inner)>>8);*output.add(2*s)=prediction as u8;*output.add(2*s+1)=(prediction>>8) as u8;for k in 0..2{train8(&features[s],&mut outer[contexts[k]],((target[s]<<12)-model[k])*7);}prev_inner=x;prev_prediction=prediction;prev_target=target[s];}
 needed as i64
}
