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
package cbench_automotive_susan_e

import "core:c"
import "core:math"

MIN_SIDE :: 11
MAX_SIDE :: 16
MAX_INPUT_LENGTH :: 258
MAX_NO_EDGES :: 2650
MASK_X :: [36]int{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1}
MASK_Y :: [36]int{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3}

abs_i :: proc "contextless" (value: int) -> int { if value < 0 { return -value }; return value }

brightness_table :: proc "contextless" (table: ^[513]u8) {
	for difference := -256; difference <= 256; difference += 1 {
		scaled := f64(abs_i(difference))/20.0
		term := scaled*scaled
		term = term*term*term
		table[difference+256] = u8(100.0*math.exp_f64(-term))
	}
}

edge_orientation :: proc "contextless" (gx, gy: int) -> (a, b, sign: int) {
	slope := f32(1_000_000.0)
	if gx != 0 { slope = f32(gy)/f32(gx) }
	sign = 1
	if slope < 0.0 { sign = -1; slope = -slope }
	if slope < 0.5 { return 0, 1, sign }
	if slope > 2.0 { return 1, 0, sign }
	if sign > 0 { return 1, 1, sign }
	return -1, 1, sign
}

symmetry_orientation :: proc "contextless" (gx, gy, cross: int) -> (a, b: int) {
	slope := f32(1_000_000.0)
	if gy != 0 { slope = f32(gx)/f32(gy) }
	if slope < 0.5 { return 0, 1 }
	if slope > 2.0 { return 1, 0 }
	if cross > 0 { return -1, 1 }
	return 1, 1
}

edge_maximum :: proc "contextless" (response: [^]int, side, y, x, a, b: int) -> bool {
	value := response[y*side+x]
	return value > response[(y+a)*side+x+b] && value >= response[(y-a)*side+x-b] &&
		value > response[(y+2*a)*side+x+2*b] && value >= response[(y-2*a)*side+x-2*b]
}

active :: proc "contextless" (middle: [^]u8, index: int) -> int {
	if middle[index] < 8 { return 1 }
	return 0
}

thin_edges :: proc "contextless" (response: [^]int, middle: [^]u8, side: int) {
	y := 4
	for y < side-4 {
		x := 4
		for x < side-4 {
			at := y*side+x
			if active(middle, at) != 0 {
				centre := response[at]
				n := active(middle,(y-1)*side+x-1)+active(middle,(y-1)*side+x)+active(middle,(y-1)*side+x+1)+
					active(middle,y*side+x-1)+active(middle,y*side+x+1)+
					active(middle,(y+1)*side+x-1)+active(middle,(y+1)*side+x)+active(middle,(y+1)*side+x+1)
				if n == 0 { middle[at] = 100 }
				if n == 1 && middle[at] < 6 {
					l := [9]int{response[(y-1)*side+x-1],response[(y-1)*side+x],response[(y-1)*side+x+1],response[y*side+x-1],0,response[y*side+x+1],response[(y+1)*side+x-1],response[(y+1)*side+x],response[(y+1)*side+x+1]}
					k := [9]int{1,1,1,1,1,1,1,1,1}
					if active(middle,(y-1)*side+x-1) != 0 { k[0]=0;k[1]=0;k[3]=0;k[2]=2;k[6]=2;k[5]=3;k[7]=3;k[8]=4 }
					else if active(middle,(y-1)*side+x) != 0 { k[1]=0;k[0]=0;k[2]=0;k[3]=2;k[5]=2;k[6]=3;k[8]=3;k[7]=4 }
					else if active(middle,(y-1)*side+x+1) != 0 { k[2]=0;k[1]=0;k[5]=0;k[0]=2;k[8]=2;k[3]=3;k[7]=3;k[6]=4 }
					else if active(middle,y*side+x-1) != 0 { k[3]=0;k[0]=0;k[6]=0;k[1]=2;k[7]=2;k[2]=3;k[8]=3;k[5]=4 }
					else if active(middle,y*side+x+1) != 0 { k[5]=0;k[2]=0;k[8]=0;k[1]=2;k[7]=2;k[0]=3;k[6]=3;k[3]=4 }
					else if active(middle,(y+1)*side+x-1) != 0 { k[6]=0;k[3]=0;k[7]=0;k[0]=2;k[8]=2;k[1]=3;k[5]=3;k[2]=4 }
					else if active(middle,(y+1)*side+x) != 0 { k[7]=0;k[6]=0;k[8]=0;k[3]=2;k[5]=2;k[0]=3;k[2]=3;k[1]=4 }
					else { k[8]=0;k[5]=0;k[7]=0;k[6]=2;k[2]=2;k[1]=3;k[3]=3;k[0]=4 }
					best, best_y, best_x := 0, 0, 0
					for yy := 0; yy < 3; yy += 1 { for xx := 0; xx < 3; xx += 1 { value := l[yy*3+xx]*k[yy*3+xx]; if value > best { best=value;best_y=yy;best_x=xx } } }
					if best > 0 {
						if middle[at] < 4 { middle[(y+best_y-1)*side+x+best_x-1] = 4 } else { middle[(y+best_y-1)*side+x+best_x-1] = middle[at]+1 }
						if best_y+best_y+best_x < 3 { y += best_y-1;x += best_x-2;if y<4{y=4};if x<4{x=4} }
					}
				}
				if n == 2 {
					b00:=active(middle,(y-1)*side+x-1);b02:=active(middle,(y-1)*side+x+1);b20:=active(middle,(y+1)*side+x-1);b22:=active(middle,(y+1)*side+x+1)
					if b00+b02+b20+b22 == 2 && ((b00|b22)&(b02|b20)) != 0 {
						mx,my:=0,0
						if b00!=0 { if b02!=0 { mx=0;my=-1 } else { mx=-1;my=0 } } else if b02!=0 { mx=1;my=0 } else { mx=0;my=1 }
						ratio:=f32(response[(y+my)*side+x+mx])/f32(centre)
						if f64(ratio)>0.7 {
							clear:=false
							if mx==0 { clear=middle[(y+2*my)*side+x-1]>7&&middle[(y+2*my)*side+x]>7&&middle[(y+2*my)*side+x+1]>7 } else { clear=middle[y*side+x+2*mx]>7&&middle[(y-1)*side+x+2*mx]>7&&middle[(y+1)*side+x+2*mx]>7 }
							if clear { middle[at]=100;middle[(y+my)*side+x+mx]=3 }
						}
					} else {
						b01:=active(middle,(y-1)*side+x);b12:=active(middle,y*side+x+1);b21:=active(middle,(y+1)*side+x);b10:=active(middle,y*side+x-1)
						angled:=b01+b12+b21+b10==2&&((b10|b12)&(b01|b21))!=0&&
							((b01!=0&&(active(middle,(y-2)*side+x-1)!=0||active(middle,(y-2)*side+x+1)!=0))||
							(b10!=0&&(active(middle,(y-1)*side+x-2)!=0||active(middle,(y+1)*side+x-2)!=0))||
							(b12!=0&&(active(middle,(y-1)*side+x+2)!=0||active(middle,(y+1)*side+x+2)!=0))||
							(b21!=0&&(active(middle,(y+2)*side+x-1)!=0||active(middle,(y+2)*side+x+1)!=0)))
						if angled { middle[at]=100;y-=1;x-=2;if y<4{y=4};if x<4{x=4} }
					}
				}
				if n > 2 {
					b01:=active(middle,(y-1)*side+x);b12:=active(middle,y*side+x+1);b21:=active(middle,(y+1)*side+x);b10:=active(middle,y*side+x-1)
					if b01+b12+b21+b10>1 {
						b00:=active(middle,(y-1)*side+x-1);b02:=active(middle,(y-1)*side+x+1);b20:=active(middle,(y+1)*side+x-1);b22:=active(middle,(y+1)*side+x+1)
						p1:=b00|b01;p2:=b02|b12;p3:=b22|b21;p4:=b20|b10
						connected:=p1+p2+p3+p4-(b01&p2)-(b12&p3)-(b21&p4)-(b10&p1)
						if connected<2 { middle[at]=100;y-=1;x-=2;if y<4{y=4};if x<4{x=4} }
					}
				}
			}
			x += 1
		}
		y += 1
	}
}

susan_edges :: proc "contextless" (image: [^]u8, side: int, brightness: ^[513]u8) {
	response: [256]int = {}
	middle: [256]u8 = {}
	for i:=0;i<side*side;i+=1 { middle[i]=100 }
	for y:=3;y<side-3;y+=1 { for x:=3;x<side-3;x+=1 {
		center:=int(image[y*side+x]);area:=100
		for k:=0;k<36;k+=1 { area+=int(brightness[center-int(image[(y+MASK_Y[k])*side+x+MASK_X[k]])+256]) }
		if area<=MAX_NO_EDGES { response[y*side+x]=MAX_NO_EDGES-area }
	} }
	for y:=4;y<side-4;y+=1 { for x:=4;x<side-4;x+=1 {
		at:=y*side+x;strength:=response[at]
		if strength<=0 { continue }
		area:=MAX_NO_EDGES-strength;do_symmetry:=area<=600
		if area>600 {
			gx,gy:=0,0
			for k:=0;k<36;k+=1 { value:=int(brightness[int(image[at])-int(image[(y+MASK_Y[k])*side+x+MASK_X[k]])+256]);gx+=MASK_X[k]*value;gy+=MASK_Y[k]*value }
			magnitude:=f32(math.sqrt_f64(f64(f32(gx*gx+gy*gy))))
			if f64(magnitude)>0.9*f64(f32(area)) { do_symmetry=false;a,b,_:=edge_orientation(gx,gy);if edge_maximum(&response[0],side,y,x,a,b) { middle[at]=1 } } else { do_symmetry=true }
		}
		if do_symmetry {
			gx,gy,cross:=0,0,0
			for k:=0;k<36;k+=1 { value:=int(brightness[int(image[at])-int(image[(y+MASK_Y[k])*side+x+MASK_X[k]])+256]);dx:=MASK_X[k];dy:=MASK_Y[k];gx+=dx*dx*value;gy+=dy*abs_i(dy)*value;cross+=dx*dy*value }
			a,b:=symmetry_orientation(gx,gy,cross)
			if edge_maximum(&response[0],side,y,x,a,b) { middle[at]=2 }
		}
	} }
	thin_edges(&response[0],&middle[0],side)
	for y:=0;y<side;y+=1 { for x:=0;x<side;x+=1 { if middle[y*side+x]<8 { at:=(y-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=255;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255 } } }
	for i:=0;i<side*side;i+=1 { if middle[i]<8 { image[i]=0 } }
}

@(export)
cbench_automotive_susan_e :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input==nil||input_length<2||input_length>MAX_INPUT_LENGTH { return -1 }
	side_value:=input[0]
	if side_value<MIN_SIDE||side_value>MAX_SIDE { return -1 }
	side:=int(side_value);count:=side*side
	if input_length!=c.size_t(count+1) { return -1 }
	image:[256]u8={}
	for i:=0;i<count;i+=1 { pixel:=input[i+1];if pixel<0||pixel>255 { return -1 };image[i]=u8(pixel) }
	if output==nil||output_capacity<c.size_t(count) { return -2 }
	brightness:[513]u8
	brightness_table(&brightness)
	susan_edges(&image[0],side,&brightness)
	for i:=0;i<count;i+=1 { output[i]=image[i] }
	return i64(count)
}
