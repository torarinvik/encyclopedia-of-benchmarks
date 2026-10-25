package picojpeg
import "core:c"
INPUT_BYTES :: 139
OUTPUT_BYTES :: 64
IDCT_Q16 :: [8]i64{11363,9633,6436,2260,-2260,-6436,-9633,-11363}

floor_q16 :: proc(value:i64)->i64 {
	if value>=0 do return value/65536
	return -((-value+65535)/65536)
}

valid_jpeg_block :: proc(v:[^]i64)->bool {
	if v[0]!=255||v[1]!=216||v[2]!=255||v[3]!=219||v[4]!=0||v[5]!=67||v[6]!=0 do return false
	for i:=0;i<64;i+=1 {if v[7+i]<1||v[7+i]>255||(i>=2&&v[7+i]!=1) do return false}
	sof:=[13]i64{255,192,0,11,8,0,8,0,8,1,1,17,0}
	for i:=0;i<13;i+=1 {if v[71+i]!=sof[i] do return false}
	if v[84]!=255||v[85]!=196||v[86]!=0||v[87]!=39||v[88]!=0||v[89]!=1||v[90]!=0||v[105]!=4||v[106]!=16||v[107]!=1||v[108]!=1||v[123]!=4||v[124]!=0 do return false
	for i:=91;i<105;i+=1 {if v[i]!=0 do return false}
	for i:=109;i<123;i+=1 {if v[i]!=0 do return false}
	sos:=[10]i64{255,218,0,8,1,1,0,0,63,0}
	for i:=0;i<10;i+=1 {if v[125+i]!=sos[i] do return false}
	return v[137]==255&&v[138]==217
}

@(export)
picojpeg :: proc "c" (values:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if values==nil||length!=c.size_t(INPUT_BYTES) do return -1
	for i:=0;i<INPUT_BYTES;i+=1 {if values[i]<0||values[i]>255 do return -1}
	if !valid_jpeg_block(values) do return -1
	scan:=u16((values[135]<<8)|values[136])
	if scan&0x8000!=0||scan&0x0400!=0||(scan>>4)&3!=2||scan&15!=15 do return -1
	dcraw:=i64((scan>>11)&15);acraw:=i64((scan>>6)&15)
	dc:=(if dcraw>=8 {dcraw} else {dcraw-15})*values[7]
	ac:=(if acraw>=8 {acraw} else {acraw-15})*values[8]
	if output==nil||capacity<c.size_t(OUTPUT_BYTES) do return -2
	for y:=0;y<8;y+=1 {for x:=0;x<8;x+=1 {
		numerator:=i64(128*65536)+dc*8192+ac*IDCT_Q16[x]+32768
		pixel:=floor_q16(numerator);if pixel<0{pixel=0};if pixel>255{pixel=255}
		output[y*8+x]=u8(pixel)
	}}
	return OUTPUT_BYTES
}
