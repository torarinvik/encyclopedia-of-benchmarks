module main
const max_cells = 1089
fn put_i64(mut output &u8, mut pos int, value i64) { bits := u64(value); for b in 0..8 { output[pos] = u8((bits >> (8*b)) & 255); pos++ } }
@[export: 'min_cost_string_conversion']
pub fn min_cost_string_conversion(input &i64, length usize, mut output &u8, capacity usize) i64 {
 unsafe {
  if input == nil || length < 6 || length > 70 { return -1 }
  sn := input[0]; if sn < 0 || sn > 32 { return -1 }; src := int(sn); dp := 1+src; if dp >= int(length) { return -1 }
  dn := input[dp]; if dn < 0 || dn > 32 { return -1 }; dst := int(dn); if int(length) != 6+src+dst { return -1 }; tp := dp+1; cp := tp+dst
  for i in 0..src { if input[1+i] < 0 || input[1+i] > 127 { return -1 } }
  for j in 0..dst { if input[tp+j] < 0 || input[tp+j] > 127 { return -1 } }
  for k in 0..4 { if input[cp+k] < -1000 || input[cp+k] > 1000 { return -1 } }
  cc:=input[cp];rc:=input[cp+1];dc:=input[cp+2];ic:=input[cp+3];rows:=src+1;cols:=dst+1;cells:=rows*cols
  mut costs:=[max_cells]i64{};mut codes:=[max_cells]i64{};mut ca:=[max_cells]i64{};mut cb:=[max_cells]i64{}
  for j in 1..cols { x:=j;costs[x]=costs[x-1]+ic;codes[x]=4;cb[x]=input[tp+j-1] }
  for i in 1..rows { x:=i*cols;costs[x]=costs[x-cols]+dc;codes[x]=3;ca[x]=input[i] }
  for i in 1..rows { for j in 1..cols { x:=i*cols+j;a:=input[i];b:=input[tp+j-1];same:=a==b;mut best:=costs[x-cols-1]+(if same {cc} else {rc});mut op:=i64(if same {1} else {2});mut aa:=a;mut bb:=i64(if same {0} else {b});deletion:=costs[x-cols]+dc;if deletion<best {best=deletion;op=3;aa=a;bb=0};insertion:=costs[x-1]+ic;if insertion<best {best=insertion;op=4;aa=0;bb=b};costs[x]=best;codes[x]=op;ca[x]=aa;cb[x]=bb } }
  needed:=32+cells*32;if output==nil||capacity<usize(needed){return -2};mut p:=0;put_i64(mut output,mut p,i64(rows));put_i64(mut output,mut p,i64(cols));for x in 0..cells{put_i64(mut output,mut p,costs[x])};put_i64(mut output,mut p,i64(rows));put_i64(mut output,mut p,i64(cols));for x in 0..cells{put_i64(mut output,mut p,codes[x]);put_i64(mut output,mut p,ca[x]);put_i64(mut output,mut p,cb[x])};return i64(p)
 }
}
