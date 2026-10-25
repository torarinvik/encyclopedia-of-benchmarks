module picojpeg
const input_bytes = 139
const output_bytes = 64
const idct_q16 = [i64(11363), 9633, 6436, 2260, -2260, -6436, -9633, -11363]!

fn floor_q16(value i64) i64 {
	if value >= 0 { return value / 65536 }
	return -((-value + 65535) / 65536)
}

fn valid_jpeg(values &i64) bool {
	if values[0]!=255||values[1]!=216||values[2]!=255||values[3]!=219||values[4]!=0||values[5]!=67||values[6]!=0 {return false}
	for i in 0..64 {if values[7+i]<1||values[7+i]>255||(i>=2&&values[7+i]!=1){return false}}
	sof:=[13]i64{255,192,0,11,8,0,8,0,8,1,1,17,0}
	for i in 0..13 {if values[71+i]!=sof[i]{return false}}
	if values[84]!=255||values[85]!=196||values[86]!=0||values[87]!=39||values[88]!=0||values[89]!=1||values[90]!=0||values[105]!=4||values[106]!=16||values[107]!=1||values[108]!=1||values[123]!=4||values[124]!=0{return false}
	for i in 91..105 {if values[i]!=0{return false}}
	for i in 109..123 {if values[i]!=0{return false}}
	sos:=[10]i64{255,218,0,8,1,1,0,0,63,0}
	for i in 0..10 {if values[125+i]!=sos[i]{return false}}
	return values[137]==255&&values[138]==217
}

@[export:'picojpeg']
pub fn picojpeg(values &i64,length usize,mut output &u8,capacity usize)i64 {
	unsafe {
		if values==nil||length!=input_bytes{return -1}
		for i in 0..length {if values[i]<0||values[i]>255{return -1}}
		if !valid_jpeg(values){return -1}
		scan:=u16((values[135]<<8)|values[136])
		if scan&0x8000!=0||scan&0x0400!=0||(scan>>4)&3!=2||scan&15!=15{return -1}
		dcraw:=i64((scan>>11)&15);acraw:=i64((scan>>6)&15)
		dc:=(if dcraw>=8 {dcraw} else {dcraw-15})*values[7]
		ac:=(if acraw>=8 {acraw} else {acraw-15})*values[8]
		if output==nil||capacity<output_bytes{return -2}
		for y in 0..8 {for x in 0..8 {mut n:=i64(128*65536)+dc*8192+ac*idct_q16[x]+32768;mut pixel:=floor_q16(n);if pixel<0{pixel=0};if pixel>255{pixel=255};output[y*8+x]=u8(pixel)}}
		return output_bytes
	}
}
