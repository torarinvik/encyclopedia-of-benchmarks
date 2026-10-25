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
const max_no_corners=1850
const mask_x=[36]int{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1}
const mask_y=[36]int{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3}
fn ftoi(value f32) int { return if value < 0 { int(f64(value)-0.5) } else { int(f64(value)+0.5) } }
fn local_corner(response [256]int,side int,y int,x int) bool {
    value:=response[y*side+x]
    for dy in -3..4 { for dx in -3..4 {
        if dx==0&&dy==0 { continue }
        other:=response[(y+dy)*side+x+dx]
        if dy<0||(dy==0&&dx<0) { if value<=other{return false} } else if value<other { return false }
    } }
    return true
}
fn brightness_table() [513]u8 {
    mut table:=[513]u8{}
    for difference in -256..257 {
        scaled:=f64(if difference<0{-difference}else{difference})/20.0
        term:=scaled*scaled
        table[difference+256]=u8(100.0*math.exp(-(term*term*term)))
    }
    return table
}
fn susan_corners(mut image [256]u8,side int,brightness [513]u8) {
    mut response:=[256]int{};mut gradient_x:=[256]int{};mut gradient_y:=[256]int{}
    mut points_x:=[256]int{};mut points_y:=[256]int{};mut point_count:=0
    for y in 5..side-5 { for x in 5..side-5 {
        center:=int(image[y*side+x]);mut area:=100
        for k in 0..36 { area+=int(brightness[center-int(image[(y+mask_y[k])*side+x+mask_x[k]])+256]) }
        if area>=max_no_corners { continue }
        mut gx:=0;mut gy:=0
        for k in 0..36 { pixel:=int(image[(y+mask_y[k])*side+x+mask_x[k]]);weight:=int(brightness[center-pixel+256]);gx+=mask_x[k]*weight;gy+=mask_y[k]*weight }
        xx:=gx*gx;yy:=gy*gy
        if xx+yy<=area*area/2 { continue }
        mut along:=0
        if yy<xx { divide:=f32(gy)/f32(if gx<0{-gx}else{gx});step_x:=(if gx<0{-gx}else{gx})/gx
            for distance in 1..4 { row:=y+ftoi(f32(distance)*divide);col:=x+distance*step_x;along+=int(brightness[center-int(image[row*side+col])+256]) }
        } else { divide:=f32(gx)/f32(if gy<0{-gy}else{gy});step_y:=(if gy<0{-gy}else{gy})/gy
            for distance in 1..4 { row:=y+distance*step_y;col:=x+ftoi(f32(distance)*divide);along+=int(brightness[center-int(image[row*side+col])+256]) }
        }
        if along>290 { at:=y*side+x;response[at]=max_no_corners-area;gradient_x[at]=51*gx/area;gradient_y[at]=51*gy/area }
    } }
    for y in 5..side-5 { for x in 5..side-5 { at:=y*side+x;if response[at]>0&&local_corner(response,side,y,x){points_x[point_count]=x;points_y[point_count]=y;point_count++} } }
    for point in 0..point_count { x:=points_x[point];y:=points_y[point];at:=(y-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=0;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255 }
    _=gradient_x;_=gradient_y
}
@[export: 'cbench_automotive_susan_c']
pub fn cbench_automotive_susan_c(input &i64,input_length usize,output &u8,output_capacity usize) i64 {
    if unsafe{input==nil}||input_length<2||input_length>max_input_length{return -1}
    side_value:=unsafe{input[0]};if side_value<min_side||side_value>max_side{return -1};side:=int(side_value);count:=side*side;if input_length!=usize(count+1){return -1}
    mut image:=[256]u8{}
    for index in 0..count { pixel:=unsafe{input[index+1]};if pixel<0||pixel>255{return -1};image[index]=u8(pixel) }
    if unsafe{output==nil}||output_capacity<usize(count){return -2}
    brightness:=brightness_table();susan_corners(mut image,side,brightness)
    for index in 0..count { unsafe{output[index]=image[index]} }
    return i64(count)
}
