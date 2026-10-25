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
const MIN_SIDE: i64 = 11;
const MAX_SIDE: i64 = 16;
const MAX_INPUT_LENGTH: usize = 258;
const MAX_NO_CORNERS: i32 = 1850;
const MASK_X = [_]i32{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1};
const MASK_Y = [_]i32{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3};
fn brightnessTable() [513]u8 { var table=[_]u8{0}**513;var d:i32= -256;while(d<=256):(d+=1){const a=if(d<0)-d else d;const s=@as(f64,@floatFromInt(a))/20.0;const q=s*s;table[@intCast(d+256)]=@intFromFloat(100.0*@exp(-(q*q*q)));}return table; }
fn ftoi(v:f32)i32{return @intFromFloat(if(v<0.0)@as(f64,v)-0.5 else @as(f64,v)+0.5);}
fn localCorner(r:*const [256]i32,side:usize,y:i32,x:i32)bool{const value=r[@intCast(y*@as(i32,@intCast(side))+x)];var dy:i32= -3;while(dy<=3):(dy+=1){var dx:i32= -3;while(dx<=3):(dx+=1){if(dx==0 and dy==0)continue;const other=r[@intCast((y+dy)*@as(i32,@intCast(side))+x+dx)];if(dy<0 or(dy==0 and dx<0)){if(value<=other)return false;}else if(value<other)return false;}}return true;}
fn susanCorners(image:*[256]u8,side:usize,brightness:*const [513]u8)void{
 var response=[_]i32{0}**256;var gradient_x=[_]i32{0}**256;var gradient_y=[_]i32{0}**256;var point_x=[_]i32{0}**256;var point_y=[_]i32{0}**256;var point_count:usize=0;
 var y:i32=5;while(y<@as(i32,@intCast(side))-5):(y+=1){var x:i32=5;while(x<@as(i32,@intCast(side))-5):(x+=1){const at=@as(usize,@intCast(y))*side+@as(usize,@intCast(x));const center=@as(i32,image[at]);var area:i32=100;for(0..36)|k|{const index=@as(usize,@intCast(y+MASK_Y[k]))*side+@as(usize,@intCast(x+MASK_X[k]));area+=brightness[@intCast(center-@as(i32,image[index])+256)];}if(area>=MAX_NO_CORNERS)continue;var gx:i32=0;var gy:i32=0;for(0..36)|k|{const index=@as(usize,@intCast(y+MASK_Y[k]))*side+@as(usize,@intCast(x+MASK_X[k]));const weight=@as(i32,brightness[@intCast(center-@as(i32,image[index])+256)]);gx+=MASK_X[k]*weight;gy+=MASK_Y[k]*weight;}const xx=gx*gx;const yy=gy*gy;if(xx+yy<=@divTrunc(area*area,2))continue;var along:i32=0;if(yy<xx){const abs_gx=if(gx<0)-gx else gx;const divide=@as(f32,@floatFromInt(gy))/@as(f32,@floatFromInt(abs_gx));const step_x=@divTrunc(abs_gx,gx);var distance:i32=1;while(distance<=3):(distance+=1){const row=y+ftoi(@as(f32,@floatFromInt(distance))*divide);const col=x+distance*step_x;const index=@as(usize,@intCast(row))*side+@as(usize,@intCast(col));along+=brightness[@intCast(center-@as(i32,image[index])+256)];}}else{const abs_gy=if(gy<0)-gy else gy;const divide=@as(f32,@floatFromInt(gx))/@as(f32,@floatFromInt(abs_gy));const step_y=@divTrunc(abs_gy,gy);var distance:i32=1;while(distance<=3):(distance+=1){const row=y+distance*step_y;const col=x+ftoi(@as(f32,@floatFromInt(distance))*divide);const index=@as(usize,@intCast(row))*side+@as(usize,@intCast(col));along+=brightness[@intCast(center-@as(i32,image[index])+256)];}}if(along>290){response[at]=MAX_NO_CORNERS-area;gradient_x[at]=@divTrunc(51*gx,area);gradient_y[at]=@divTrunc(51*gy,area);}}}
 y=5;while(y<@as(i32,@intCast(side))-5):(y+=1){var x:i32=5;while(x<@as(i32,@intCast(side))-5):(x+=1){const at=@as(usize,@intCast(y))*side+@as(usize,@intCast(x));if(response[at]>0 and localCorner(&response,side,y,x)){point_x[point_count]=x;point_y[point_count]=y;point_count+=1;}}}
 for(0..point_count)|p|{const x:usize=@intCast(point_x[p]);const py:usize=@intCast(point_y[p]);const at=(py-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=0;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255;}_=gradient_x;_=gradient_y;
}
pub export fn cbench_automotive_susan_c(input:[*c]const i64,input_length:usize,output:[*c]u8,output_capacity:usize)i64{
 if(input==null or input_length<2 or input_length>MAX_INPUT_LENGTH)return -1;const side_value=input[0];if(side_value<MIN_SIDE or side_value>MAX_SIDE)return -1;const side:usize=@intCast(side_value);const count=side*side;if(input_length!=count+1)return -1;var image=[_]u8{0}**256;for(0..count)|index|{const pixel=input[index+1];if(pixel<0 or pixel>255)return -1;image[index]=@intCast(pixel);}if(output==null or output_capacity<count)return -2;const brightness=brightnessTable();susanCorners(&image,side,&brightness);for(0..count)|index|output[index]=image[index];return @intCast(count);
}
