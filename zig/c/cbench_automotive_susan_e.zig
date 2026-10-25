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
const MAX_NO_EDGES: i32 = 2650;
const MASK_X = [_]i32{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1};
const MASK_Y = [_]i32{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3};
const EdgeDir = struct { a:i32, b:i32, sign:i32 };
const SymDir = struct { a:i32, b:i32 };
fn brightnessTable() [513]u8 {var t=[_]u8{0}**513;var d:i32= -256;while(d<=256):(d+=1){const a=if(d<0)-d else d;const s=@as(f64,@floatFromInt(a))/20.0;const q=s*s;t[@intCast(d+256)]=@intFromFloat(100.0*@exp(-(q*q*q)));}return t;}
fn edgeOrientation(gx:i32,gy:i32)EdgeDir{var slope:f32=if(gx==0)1000000.0 else @as(f32,@floatFromInt(gy))/@as(f32,@floatFromInt(gx));const sign:i32=if(slope<0.0)-1 else 1;if(slope<0.0)slope= -slope;if(slope<0.5)return .{.a=0,.b=1,.sign=sign};if(slope>2.0)return .{.a=1,.b=0,.sign=sign};return .{.a=if(sign>0)1 else -1,.b=1,.sign=sign};}
fn symmetryOrientation(gx:i32,gy:i32,cross:i32)SymDir{const slope:f32=if(gy==0)1000000.0 else @as(f32,@floatFromInt(gx))/@as(f32,@floatFromInt(gy));if(slope<0.5)return .{.a=0,.b=1};if(slope>2.0)return .{.a=1,.b=0};return .{.a=if(cross>0)-1 else 1,.b=1};}
fn active(m:*const [256]u8,at:usize)i32{return if(m[at]<8)1 else 0;}
fn edgeMaximum(r:*const [256]i32,side:usize,y:i32,x:i32,a:i32,b:i32)bool{const s=@as(i32,@intCast(side));const v=r[@intCast(y*s+x)];return v>r[@intCast((y+a)*s+x+b)] and v>=r[@intCast((y-a)*s+x-b)] and v>r[@intCast((y+2*a)*s+x+2*b)] and v>=r[@intCast((y-2*a)*s+x-2*b)];}
fn thinEdges(r:*const [256]i32,m:*[256]u8,side:usize)void{
 var y:i32=4;const s=@as(i32,@intCast(side));while(y<s-4):(y+=1){var x:i32=4;while(x<s-4):(x+=1){const at:usize=@intCast(y*s+x);if(active(m,at)!=0){const centre=r[at];const n=active(m,@intCast((y-1)*s+x-1))+active(m,@intCast((y-1)*s+x))+active(m,@intCast((y-1)*s+x+1))+active(m,@intCast(y*s+x-1))+active(m,@intCast(y*s+x+1))+active(m,@intCast((y+1)*s+x-1))+active(m,@intCast((y+1)*s+x))+active(m,@intCast((y+1)*s+x+1));
  if(n==0)m[at]=100;
  if(n==1 and m[at]<6){const l=[_]i32{r[@intCast((y-1)*s+x-1)],r[@intCast((y-1)*s+x)],r[@intCast((y-1)*s+x+1)],r[@intCast(y*s+x-1)],0,r[@intCast(y*s+x+1)],r[@intCast((y+1)*s+x-1)],r[@intCast((y+1)*s+x)],r[@intCast((y+1)*s+x+1)]};var k=[_]i32{1,1,1,1,1,1,1,1,1};
   if(active(m,@intCast((y-1)*s+x-1))!=0){k[0]=0;k[1]=0;k[3]=0;k[2]=2;k[6]=2;k[5]=3;k[7]=3;k[8]=4;}else if(active(m,@intCast((y-1)*s+x))!=0){k[1]=0;k[0]=0;k[2]=0;k[3]=2;k[5]=2;k[6]=3;k[8]=3;k[7]=4;}else if(active(m,@intCast((y-1)*s+x+1))!=0){k[2]=0;k[1]=0;k[5]=0;k[0]=2;k[8]=2;k[3]=3;k[7]=3;k[6]=4;}else if(active(m,@intCast(y*s+x-1))!=0){k[3]=0;k[0]=0;k[6]=0;k[1]=2;k[7]=2;k[2]=3;k[8]=3;k[5]=4;}else if(active(m,@intCast(y*s+x+1))!=0){k[5]=0;k[2]=0;k[8]=0;k[1]=2;k[7]=2;k[0]=3;k[6]=3;k[3]=4;}else if(active(m,@intCast((y+1)*s+x-1))!=0){k[6]=0;k[3]=0;k[7]=0;k[0]=2;k[8]=2;k[1]=3;k[5]=3;k[2]=4;}else if(active(m,@intCast((y+1)*s+x))!=0){k[7]=0;k[6]=0;k[8]=0;k[3]=2;k[5]=2;k[0]=3;k[2]=3;k[1]=4;}else{k[8]=0;k[5]=0;k[7]=0;k[6]=2;k[2]=2;k[1]=3;k[3]=3;k[0]=4;}
   var best:i32=0;var by:i32=0;var bx:i32=0;for(0..3)|yy|{for(0..3)|xx|{const value=l[yy*3+xx]*k[yy*3+xx];if(value>best){best=value;by=@intCast(yy);bx=@intCast(xx);}}}if(best>0){m[@intCast((y+by-1)*s+x+bx-1)]=if(m[at]<4)4 else m[at]+1;if(by+by+bx<3){y+=by-1;x+=bx-2;if(y<4)y=4;if(x<4)x=4;}}
  }
  if(n==2){const b00=active(m,@intCast((y-1)*s+x-1));const b02=active(m,@intCast((y-1)*s+x+1));const b20=active(m,@intCast((y+1)*s+x-1));const b22=active(m,@intCast((y+1)*s+x+1));if(b00+b02+b20+b22==2 and ((b00|b22)&(b02|b20))!=0){var mx:i32=0;var my:i32=0;if(b00!=0){if(b02!=0)my= -1 else mx= -1;}else if(b02!=0)mx=1 else my=1;const ratio=@as(f32,@floatFromInt(r[@intCast((y+my)*s+x+mx)]))/@as(f32,@floatFromInt(centre));if(ratio>0.7){const clear=if(mx==0)m[@intCast((y+2*my)*s+x-1)]>7 and m[@intCast((y+2*my)*s+x)]>7 and m[@intCast((y+2*my)*s+x+1)]>7 else m[@intCast(y*s+x+2*mx)]>7 and m[@intCast((y-1)*s+x+2*mx)]>7 and m[@intCast((y+1)*s+x+2*mx)]>7;if(clear){m[at]=100;m[@intCast((y+my)*s+x+mx)]=3;}}}else{const b01=active(m,@intCast((y-1)*s+x));const b12=active(m,@intCast(y*s+x+1));const b21=active(m,@intCast((y+1)*s+x));const b10=active(m,@intCast(y*s+x-1));const angled=b01+b12+b21+b10==2 and ((b10|b12)&(b01|b21))!=0 and ((b01!=0 and (active(m,@intCast((y-2)*s+x-1))!=0 or active(m,@intCast((y-2)*s+x+1))!=0)) or (b10!=0 and (active(m,@intCast((y-1)*s+x-2))!=0 or active(m,@intCast((y+1)*s+x-2))!=0)) or (b12!=0 and (active(m,@intCast((y-1)*s+x+2))!=0 or active(m,@intCast((y+1)*s+x+2))!=0)) or (b21!=0 and (active(m,@intCast((y+2)*s+x-1))!=0 or active(m,@intCast((y+2)*s+x+1))!=0)));if(angled){m[at]=100;y-=1;x-=2;if(y<4)y=4;if(x<4)x=4;}}}
  if(n>2){const b01=active(m,@intCast((y-1)*s+x));const b12=active(m,@intCast(y*s+x+1));const b21=active(m,@intCast((y+1)*s+x));const b10=active(m,@intCast(y*s+x-1));if(b01+b12+b21+b10>1){const b00=active(m,@intCast((y-1)*s+x-1));const b02=active(m,@intCast((y-1)*s+x+1));const b20=active(m,@intCast((y+1)*s+x-1));const b22=active(m,@intCast((y+1)*s+x+1));const p1=b00|b01;const p2=b02|b12;const p3=b22|b21;const p4=b20|b10;const connected=p1+p2+p3+p4-(b01&p2)-(b12&p3)-(b21&p4)-(b10&p1);if(connected<2){m[at]=100;y-=1;x-=2;if(y<4)y=4;if(x<4)x=4;}}}
 }} }
}
fn susanEdges(image:*[256]u8,side:usize,brightness:*const[513]u8)void{var response=[_]i32{0}**256;var middle=[_]u8{100}**256;const s=@as(i32,@intCast(side));var y:i32=3;while(y<s-3):(y+=1){var x:i32=3;while(x<s-3):(x+=1){const at:usize=@intCast(y*s+x);const center=@as(i32,image[at]);var area:i32=100;for(0..36)|k|{const idx=@as(usize,@intCast(y+MASK_Y[k]))*side+@as(usize,@intCast(x+MASK_X[k]));area+=brightness[@intCast(center-@as(i32,image[idx])+256)];}if(area<=MAX_NO_EDGES)response[at]=MAX_NO_EDGES-area;}}
 y=4;while(y<s-4):(y+=1){var x:i32=4;while(x<s-4):(x+=1){const at:usize=@intCast(y*s+x);const strength=response[at];if(strength<=0)continue;const area=MAX_NO_EDGES-strength;var do_symmetry=area<=600;if(area>600){var gx:i32=0;var gy:i32=0;for(0..36)|k|{const idx=@as(usize,@intCast(y+MASK_Y[k]))*side+@as(usize,@intCast(x+MASK_X[k]));const value=@as(i32,brightness[@intCast(@as(i32,image[at])-@as(i32,image[idx])+256)]);gx+=MASK_X[k]*value;gy+=MASK_Y[k]*value;}const mag=@sqrt(@as(f32,@floatFromInt(gx*gx+gy*gy)));if(mag>0.9*@as(f32,@floatFromInt(area))){do_symmetry=false;const dir=edgeOrientation(gx,gy);if(edgeMaximum(&response,side,y,x,dir.a,dir.b))middle[at]=1;}else do_symmetry=true;}if(do_symmetry){var gx:i32=0;var gy:i32=0;var cross:i32=0;for(0..36)|k|{const idx=@as(usize,@intCast(y+MASK_Y[k]))*side+@as(usize,@intCast(x+MASK_X[k]));const value=@as(i32,brightness[@intCast(@as(i32,image[at])-@as(i32,image[idx])+256)]);const dx=MASK_X[k];const dy=MASK_Y[k];gx+=dx*dx*value;gy+=dy*@as(i32,@abs(dy))*value;cross+=dx*dy*value;}const dir=symmetryOrientation(gx,gy,cross);if(edgeMaximum(&response,side,y,x,dir.a,dir.b))middle[at]=2;}}}
 thinEdges(&response,&middle,side);for(0..side)|yy|{for(0..side)|xx|{if(middle[yy*side+xx]<8){const at=(yy-1)*side+xx-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=255;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255;}}}for(0..side*side)|i|{if(middle[i]<8)image[i]=0;}}
pub export fn cbench_automotive_susan_e(input:[*c]const i64,input_length:usize,output:[*c]u8,output_capacity:usize)i64{if(input==null or input_length<2 or input_length>MAX_INPUT_LENGTH)return -1;const side_value=input[0];if(side_value<MIN_SIDE or side_value>MAX_SIDE)return -1;const side:usize=@intCast(side_value);const count=side*side;if(input_length!=count+1)return -1;var image=[_]u8{0}**256;for(0..count)|i|{const pixel=input[i+1];if(pixel<0 or pixel>255)return -1;image[i]=@intCast(pixel);}if(output==null or output_capacity<count)return -2;const brightness=brightnessTable();susanEdges(&image,side,&brightness);for(0..count)|i|output[i]=image[i];return @intCast(count);}
