/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
module main
import math
const min_side=11
const max_side=16
const max_input_length=258
const max_no_edges=2650
const mask_x=[36]int{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1}
const mask_y=[36]int{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3}
fn brightness_table() [513]u8 { mut t:=[513]u8{};for d in -256..257{s:=f64(if d<0{-d}else{d})/20.0;q:=s*s;t[d+256]=u8(100.0*math.exp(-(q*q*q)))};return t }
fn edge_orientation(gx int,gy int)(int,int,int){mut slope:=if gx==0{f32(1000000.0)}else{f32(gy)/f32(gx)};sign:=if slope<0.0{ -1 }else{1};if slope<0.0{slope= -slope};if slope<0.5{return 0,1,sign};if slope>2.0{return 1,0,sign};return if sign>0{1}else{ -1},1,sign}
fn symmetry_orientation(gx int,gy int,cross int)(int,int){slope:=if gy==0{f32(1000000.0)}else{f32(gx)/f32(gy)};if slope<0.5{return 0,1};if slope>2.0{return 1,0};return if cross>0{ -1}else{1},1}
fn edge_maximum(response [256]int,side int,y int,x int,a int,b int) bool {v:=response[y*side+x];return v>response[(y+a)*side+x+b]&&v>=response[(y-a)*side+x-b]&&v>response[(y+2*a)*side+x+2*b]&&v>=response[(y-2*a)*side+x-2*b]}
fn active(middle [256]u8,at int) int {return if middle[at]<8{1}else{0}}
fn thin_edges(response [256]int,mut middle [256]u8,side int){
 mut y:=4
 for y<side-4{mut x:=4;for x<side-4{at:=y*side+x;if active(middle,at)!=0{centre:=response[at];n:=active(middle,(y-1)*side+x-1)+active(middle,(y-1)*side+x)+active(middle,(y-1)*side+x+1)+active(middle,y*side+x-1)+active(middle,y*side+x+1)+active(middle,(y+1)*side+x-1)+active(middle,(y+1)*side+x)+active(middle,(y+1)*side+x+1)
 if n==0{middle[at]=100}
 if n==1&&middle[at]<6{l:=[9]int{response[(y-1)*side+x-1],response[(y-1)*side+x],response[(y-1)*side+x+1],response[y*side+x-1],0,response[y*side+x+1],response[(y+1)*side+x-1],response[(y+1)*side+x],response[(y+1)*side+x+1]};mut k:=[9]int{1,1,1,1,1,1,1,1,1}
 if active(middle,(y-1)*side+x-1)!=0{k[0]=0;k[1]=0;k[3]=0;k[2]=2;k[6]=2;k[5]=3;k[7]=3;k[8]=4}else if active(middle,(y-1)*side+x)!=0{k[1]=0;k[0]=0;k[2]=0;k[3]=2;k[5]=2;k[6]=3;k[8]=3;k[7]=4}else if active(middle,(y-1)*side+x+1)!=0{k[2]=0;k[1]=0;k[5]=0;k[0]=2;k[8]=2;k[3]=3;k[7]=3;k[6]=4}else if active(middle,y*side+x-1)!=0{k[3]=0;k[0]=0;k[6]=0;k[1]=2;k[7]=2;k[2]=3;k[8]=3;k[5]=4}else if active(middle,y*side+x+1)!=0{k[5]=0;k[2]=0;k[8]=0;k[1]=2;k[7]=2;k[0]=3;k[6]=3;k[3]=4}else if active(middle,(y+1)*side+x-1)!=0{k[6]=0;k[3]=0;k[7]=0;k[0]=2;k[8]=2;k[1]=3;k[5]=3;k[2]=4}else if active(middle,(y+1)*side+x)!=0{k[7]=0;k[6]=0;k[8]=0;k[3]=2;k[5]=2;k[0]=3;k[2]=3;k[1]=4}else{k[8]=0;k[5]=0;k[7]=0;k[6]=2;k[2]=2;k[1]=3;k[3]=3;k[0]=4}
 mut best:=0;mut best_y:=0;mut best_x:=0;for yy in 0..3{for xx in 0..3{value:=l[yy*3+xx]*k[yy*3+xx];if value>best{best=value;best_y=yy;best_x=xx}}};if best>0{middle[(y+best_y-1)*side+x+best_x-1]=if middle[at]<4{u8(4)}else{middle[at]+1};if best_y+best_y+best_x<3{y+=best_y-1;x+=best_x-2;if y<4{y=4};if x<4{x=4}}}}
 if n==2{b00:=active(middle,(y-1)*side+x-1);b02:=active(middle,(y-1)*side+x+1);b20:=active(middle,(y+1)*side+x-1);b22:=active(middle,(y+1)*side+x+1);if b00+b02+b20+b22==2&&((b00|b22)&(b02|b20))!=0{mut mx:=0;mut my:=0;if b00!=0{if b02!=0{my= -1}else{mx= -1}}else if b02!=0{mx=1}else{my=1};ratio:=f32(response[(y+my)*side+x+mx])/f32(centre);if ratio>0.7{clear:=if mx==0{middle[(y+2*my)*side+x-1]>7&&middle[(y+2*my)*side+x]>7&&middle[(y+2*my)*side+x+1]>7}else{middle[y*side+x+2*mx]>7&&middle[(y-1)*side+x+2*mx]>7&&middle[(y+1)*side+x+2*mx]>7};if clear{middle[at]=100;middle[(y+my)*side+x+mx]=3}}}else{b01:=active(middle,(y-1)*side+x);b12:=active(middle,y*side+x+1);b21:=active(middle,(y+1)*side+x);b10:=active(middle,y*side+x-1);angled:=b01+b12+b21+b10==2&&((b10|b12)&(b01|b21))!=0&&((b01!=0&&(active(middle,(y-2)*side+x-1)!=0||active(middle,(y-2)*side+x+1)!=0))||(b10!=0&&(active(middle,(y-1)*side+x-2)!=0||active(middle,(y+1)*side+x-2)!=0))||(b12!=0&&(active(middle,(y-1)*side+x+2)!=0||active(middle,(y+1)*side+x+2)!=0))||(b21!=0&&(active(middle,(y+2)*side+x-1)!=0||active(middle,(y+2)*side+x+1)!=0)));if angled{middle[at]=100;y--;x-=2;if y<4{y=4};if x<4{x=4}}}}
 if n>2{b01:=active(middle,(y-1)*side+x);b12:=active(middle,y*side+x+1);b21:=active(middle,(y+1)*side+x);b10:=active(middle,y*side+x-1);if b01+b12+b21+b10>1{b00:=active(middle,(y-1)*side+x-1);b02:=active(middle,(y-1)*side+x+1);b20:=active(middle,(y+1)*side+x-1);b22:=active(middle,(y+1)*side+x+1);p1:=b00|b01;p2:=b02|b12;p3:=b22|b21;p4:=b20|b10;connected:=p1+p2+p3+p4-(b01&p2)-(b12&p3)-(b21&p4)-(b10&p1);if connected<2{middle[at]=100;y--;x-=2;if y<4{y=4};if x<4{x=4}}}}
 };x++};y++}
}
fn susan_edges(mut image [256]u8,side int,brightness [513]u8){mut response:=[256]int{};mut middle:=[256]u8{};for i in 0..side*side{middle[i]=100};for y in 3..side-3{for x in 3..side-3{center:=int(image[y*side+x]);mut area:=100;for k in 0..36{area+=int(brightness[center-int(image[(y+mask_y[k])*side+x+mask_x[k]])+256])};if area<=max_no_edges{response[y*side+x]=max_no_edges-area}}}
 for y in 4..side-4{for x in 4..side-4{at:=y*side+x;strength:=response[at];if strength<=0{continue};area:=max_no_edges-strength;mut do_symmetry:=area<=600;if area>600{mut gx:=0;mut gy:=0;for k in 0..36{value:=int(brightness[int(image[at])-int(image[(y+mask_y[k])*side+x+mask_x[k]])+256]);gx+=mask_x[k]*value;gy+=mask_y[k]*value};magnitude:=f32(math.sqrt(f64(gx*gx+gy*gy)));if magnitude>0.9*f32(area){do_symmetry=false;a,b,_:=edge_orientation(gx,gy);if edge_maximum(response,side,y,x,a,b){middle[at]=1}}else{do_symmetry=true}};if do_symmetry{mut gx:=0;mut gy:=0;mut cross:=0;for k in 0..36{value:=int(brightness[int(image[at])-int(image[(y+mask_y[k])*side+x+mask_x[k]])+256]);dx:=mask_x[k];dy:=mask_y[k];gx+=dx*dx*value;gy+=dy*abs(dy)*value;cross+=dx*dy*value};a,b:=symmetry_orientation(gx,gy,cross);if edge_maximum(response,side,y,x,a,b){middle[at]=2}}}}
 thin_edges(response,mut middle,side);for y in 0..side{for x in 0..side{if middle[y*side+x]<8{at:=(y-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=255;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255}}};for i in 0..side*side{if middle[i]<8{image[i]=0}}
}
@[export: 'cbench_automotive_susan_e']
pub fn cbench_automotive_susan_e(input &i64,input_length usize,output &u8,output_capacity usize) i64 {
 if unsafe{input==nil}||input_length<2||input_length>max_input_length{return -1};side_value:=unsafe{input[0]};if side_value<min_side||side_value>max_side{return -1};side:=int(side_value);count:=side*side;if input_length!=usize(count+1){return -1};mut image:=[256]u8{}
 for i in 0..count{pixel:=unsafe{input[i+1]};if pixel<0||pixel>255{return -1};image[i]=u8(pixel)};if unsafe{output==nil}||output_capacity<usize(count){return -2};brightness:=brightness_table();susan_edges(mut image,side,brightness);for i in 0..count{unsafe{output[i]=image[i]}};return i64(count)
}
