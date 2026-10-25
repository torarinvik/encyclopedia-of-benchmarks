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
const MASK_X: [i32; 36] = [-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1];
const MASK_Y: [i32; 36] = [-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3];

fn brightness_table() -> [u8; 513] { let mut t=[0u8;513];for d in -256i32..=256{let s=f64::from(d.abs())/20.0;let q=s*s; t[(d+256) as usize]=(100.0*(-q*q*q).exp()) as u8;}t }
fn edge_orientation(gx:i32,gy:i32)->(i32,i32,i32){let mut slope=if gx==0{1_000_000.0f32}else{gy as f32/gx as f32};let sign=if slope<0.0{-1}else{1};if slope<0.0{slope=-slope;}if slope<0.5{(0,1,sign)}else if slope>2.0{(1,0,sign)}else{(if sign>0{1}else{-1},1,sign)}}
fn symmetry_orientation(gx:i32,gy:i32,cross:i32)->(i32,i32){let slope=if gy==0{1_000_000.0f32}else{gx as f32/gy as f32};if slope<0.5{(0,1)}else if slope>2.0{(1,0)}else{(if cross>0{-1}else{1},1)}}
fn edge_maximum(r:&[i32;256],side:usize,y:i32,x:i32,a:i32,b:i32)->bool{let v=r[y as usize*side+x as usize];v>r[((y+a)as usize)*side+(x+b)as usize]&&v>=r[((y-a)as usize)*side+(x-b)as usize]&&v>r[((y+2*a)as usize)*side+(x+2*b)as usize]&&v>=r[((y-2*a)as usize)*side+(x-2*b)as usize]}
fn active(m:&[u8;256],i:usize)->i32{if m[i]<8{1}else{0}}

fn thin_edges(response:&[i32;256],middle:&mut [u8;256],side:usize){
    let mut y=4i32;while y<(side as i32)-4{let mut x=4i32;while x<(side as i32)-4{let at=y as usize*side+x as usize;if active(middle,at)!=0{let centre=response[at];let n=active(middle,((y-1)as usize)*side+(x-1)as usize)+active(middle,((y-1)as usize)*side+x as usize)+active(middle,((y-1)as usize)*side+(x+1)as usize)+active(middle,y as usize*side+(x-1)as usize)+active(middle,y as usize*side+(x+1)as usize)+active(middle,((y+1)as usize)*side+(x-1)as usize)+active(middle,((y+1)as usize)*side+x as usize)+active(middle,((y+1)as usize)*side+(x+1)as usize);
        if n==0{middle[at]=100;}
        if n==1&&middle[at]<6{let l=[response[(y-1)as usize*side+(x-1)as usize],response[(y-1)as usize*side+x as usize],response[(y-1)as usize*side+(x+1)as usize],response[y as usize*side+(x-1)as usize],0,response[y as usize*side+(x+1)as usize],response[(y+1)as usize*side+(x-1)as usize],response[(y+1)as usize*side+x as usize],response[(y+1)as usize*side+(x+1)as usize]];let mut k=[1i32;9];
          if active(middle,(y-1)as usize*side+(x-1)as usize)!=0{k[0]=0;k[1]=0;k[3]=0;k[2]=2;k[6]=2;k[5]=3;k[7]=3;k[8]=4;}else if active(middle,(y-1)as usize*side+x as usize)!=0{k[1]=0;k[0]=0;k[2]=0;k[3]=2;k[5]=2;k[6]=3;k[8]=3;k[7]=4;}else if active(middle,(y-1)as usize*side+(x+1)as usize)!=0{k[2]=0;k[1]=0;k[5]=0;k[0]=2;k[8]=2;k[3]=3;k[7]=3;k[6]=4;}else if active(middle,y as usize*side+(x-1)as usize)!=0{k[3]=0;k[0]=0;k[6]=0;k[1]=2;k[7]=2;k[2]=3;k[8]=3;k[5]=4;}else if active(middle,y as usize*side+(x+1)as usize)!=0{k[5]=0;k[2]=0;k[8]=0;k[1]=2;k[7]=2;k[0]=3;k[6]=3;k[3]=4;}else if active(middle,(y+1)as usize*side+(x-1)as usize)!=0{k[6]=0;k[3]=0;k[7]=0;k[0]=2;k[8]=2;k[1]=3;k[5]=3;k[2]=4;}else if active(middle,(y+1)as usize*side+x as usize)!=0{k[7]=0;k[6]=0;k[8]=0;k[3]=2;k[5]=2;k[0]=3;k[2]=3;k[1]=4;}else{k[8]=0;k[5]=0;k[7]=0;k[6]=2;k[2]=2;k[1]=3;k[3]=3;k[0]=4;}
          let(mut best,mut by,mut bx)=(0,0,0);for yy in 0..3{for xx in 0..3{let value=l[yy*3+xx]*k[yy*3+xx];if value>best{best=value;by=yy as i32;bx=xx as i32;}}}if best>0{middle[((y+by-1)as usize)*side+(x+bx-1)as usize]=if middle[at]<4{4}else{middle[at]+1};if by+by+bx<3{y+=by-1;x+=bx-2;if y<4{y=4;}if x<4{x=4;}}}
        }
        if n==2{let b00=active(middle,(y-1)as usize*side+(x-1)as usize);let b02=active(middle,(y-1)as usize*side+(x+1)as usize);let b20=active(middle,(y+1)as usize*side+(x-1)as usize);let b22=active(middle,(y+1)as usize*side+(x+1)as usize);if b00+b02+b20+b22==2&&((b00|b22)&(b02|b20))!=0{let(mx,my)=if b00!=0{if b02!=0{(0,-1)}else{(-1,0)}}else if b02!=0{(1,0)}else{(0,1)};let ratio=response[((y+my)as usize)*side+(x+mx)as usize] as f32/centre as f32;if ratio>0.7{let clear=if mx==0{middle[((y+2*my)as usize)*side+(x-1)as usize]>7&&middle[((y+2*my)as usize)*side+x as usize]>7&&middle[((y+2*my)as usize)*side+(x+1)as usize]>7}else{middle[y as usize*side+(x+2*mx)as usize]>7&&middle[((y-1)as usize)*side+(x+2*mx)as usize]>7&&middle[((y+1)as usize)*side+(x+2*mx)as usize]>7};if clear{middle[at]=100;middle[((y+my)as usize)*side+(x+mx)as usize]=3;}}}else{let b01=active(middle,(y-1)as usize*side+x as usize);let b12=active(middle,y as usize*side+(x+1)as usize);let b21=active(middle,(y+1)as usize*side+x as usize);let b10=active(middle,y as usize*side+(x-1)as usize);let angled=b01+b12+b21+b10==2&&((b10|b12)&(b01|b21))!=0&&((b01!=0&&(active(middle,(y-2)as usize*side+(x-1)as usize)!=0||active(middle,(y-2)as usize*side+(x+1)as usize)!=0))||(b10!=0&&(active(middle,(y-1)as usize*side+(x-2)as usize)!=0||active(middle,(y+1)as usize*side+(x-2)as usize)!=0))||(b12!=0&&(active(middle,(y-1)as usize*side+(x+2)as usize)!=0||active(middle,(y+1)as usize*side+(x+2)as usize)!=0))||(b21!=0&&(active(middle,(y+2)as usize*side+(x-1)as usize)!=0||active(middle,(y+2)as usize*side+(x+1)as usize)!=0)));if angled{middle[at]=100;y-=1;x-=2;if y<4{y=4;}if x<4{x=4;}}}}
        if n>2{let b01=active(middle,(y-1)as usize*side+x as usize);let b12=active(middle,y as usize*side+(x+1)as usize);let b21=active(middle,(y+1)as usize*side+x as usize);let b10=active(middle,y as usize*side+(x-1)as usize);if b01+b12+b21+b10>1{let b00=active(middle,(y-1)as usize*side+(x-1)as usize);let b02=active(middle,(y-1)as usize*side+(x+1)as usize);let b20=active(middle,(y+1)as usize*side+(x-1)as usize);let b22=active(middle,(y+1)as usize*side+(x+1)as usize);let p1=b00|b01;let p2=b02|b12;let p3=b22|b21;let p4=b20|b10;let connected=p1+p2+p3+p4-(b01&p2)-(b12&p3)-(b21&p4)-(b10&p1);if connected<2{middle[at]=100;y-=1;x-=2;if y<4{y=4;}if x<4{x=4;}}}}
    }x+=1;}y+=1;}
}
fn susan_edges(image:&mut [u8;256],side:usize,brightness:&[u8;513]){let mut response=[0i32;256];let mut middle=[100u8;256];for y in 3i32..side as i32-3{for x in 3i32..side as i32-3{let center=image[y as usize*side+x as usize] as i32;let mut area=100;for k in 0..36{area+=brightness[(center-image[((y+MASK_Y[k])as usize)*side+(x+MASK_X[k])as usize] as i32+256)as usize] as i32;}if area<=MAX_NO_EDGES{response[y as usize*side+x as usize]=MAX_NO_EDGES-area;}}}
for y in 4i32..side as i32-4{for x in 4i32..side as i32-4{let at=y as usize*side+x as usize;let strength=response[at];if strength<=0{continue;}let area=MAX_NO_EDGES-strength;let mut do_symmetry=area<=600;if area>600{let(mut gx,mut gy)=(0,0);for k in 0..36{let value=brightness[(image[at] as i32-image[((y+MASK_Y[k])as usize)*side+(x+MASK_X[k])as usize] as i32+256)as usize] as i32;gx+=MASK_X[k]*value;gy+=MASK_Y[k]*value;}let magnitude=((gx*gx+gy*gy)as f32).sqrt();if magnitude>0.9*(area as f32){do_symmetry=false;let(a,b,_)=edge_orientation(gx,gy);if edge_maximum(&response,side,y,x,a,b){middle[at]=1;}}else{do_symmetry=true;}}
if do_symmetry{let(mut gx,mut gy,mut cross)=(0,0,0);for k in 0..36{let value=brightness[(image[at] as i32-image[((y+MASK_Y[k])as usize)*side+(x+MASK_X[k])as usize] as i32+256)as usize] as i32;let dx=MASK_X[k];let dy=MASK_Y[k];gx+=dx*dx*value;gy+=dy*dy.abs()*value;cross+=dx*dy*value;}let(a,b)=symmetry_orientation(gx,gy,cross);if edge_maximum(&response,side,y,x,a,b){middle[at]=2;}}}}
thin_edges(&response,&mut middle,side);for y in 0..side{for x in 0..side{if middle[y*side+x]<8{let at=(y-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=255;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255;}}}for i in 0..side*side{if middle[i]<8{image[i]=0;}}}
#[no_mangle]
pub unsafe extern "C" fn cbench_automotive_susan_e(input:*const i64,input_length:usize,output:*mut u8,output_capacity:usize)->i64{if input.is_null()||input_length<2||input_length>MAX_INPUT_LENGTH{return -1;}let side_value=*input;if !(MIN_SIDE..=MAX_SIDE).contains(&side_value){return -1;}let side=side_value as usize;let count=side*side;if input_length!=count+1{return -1;}let mut image=[0u8;256];for i in 0..count{let pixel=*input.add(i+1);if !(0..=255).contains(&pixel){return -1;}image[i]=pixel as u8;}if output.is_null()||output_capacity<count{return -2;}let brightness=brightness_table();susan_edges(&mut image,side,&brightness);for i in 0..count{*output.add(i)=image[i];}count as i64}
