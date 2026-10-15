module exponential_moving_average_java_stream;

fn void put_f64_le(char* output, usz offset, double value) {
	ulong bits = @bitcast(ulong, value);
	for (usz byte = 0; byte < 8; byte++) output[offset+byte] = (char)((bits >> (8*byte)) & 255);
}
fn void put_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; byte++) output[offset+byte] = (char)((bits >> (8*byte)) & 255);
}

fn long exponential_moving_average_java_stream(long* input, usz length, char* output, usz capacity) @export("exponential_moving_average_java_stream") {
	if (input == null || length < 2 || input[1] < 0 || input[1] > 256 || length != 2+(usz)input[1]) return -1;
	if (input[0] < -1000000 || input[0] > 1000000) return -1;
	double mean=(double)input[0],variance=0.0;
	for (usz i=0;i<(usz)input[1];i++) {
		if(input[i+2]<-1000000||input[i+2]>1000000)return -1;
		double value=(double)input[i+2],deviation=value-mean;
		mean += 0.25*deviation;
		variance = 0.75*(variance+0.25*deviation*deviation);
	}
	if(output==null||capacity<24)return -2;
	put_f64_le(output,0,mean);put_f64_le(output,8,variance);put_i64_le(output,16,input[1]);
	return 24;
}
