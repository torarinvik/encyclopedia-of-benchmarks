module euler_method_julia;

fn void put_f64_le(char* output, usz offset, double value) {
	ulong bits = @bitcast(ulong, value);
	for (usz byte = 0; byte < 8; byte++) output[offset+byte] = (char)((bits >> (8*byte)) & 255);
}

fn long euler_method_julia(long* input, usz length, char* output, usz capacity) @export("euler_method_julia") {
	if(input==null||length!=3||input[0]<-8||input[0]>8||input[1]<1||input[1]>16||input[2]<1||input[2]>4)return -1;
	usz steps=(usz)input[1],required=16*steps;if(output==null||capacity<required)return -2;
	double states[16],times[16];states[0]=(double)input[0];times[0]=0.0;
	double h=1.0/(double)(1<<input[2]);
	for(usz i=0;i+1<steps;i++){states[i+1]=states[i]+h*(states[i]+times[i]);times[i+1]=times[i]+h;}
	for(usz i=0;i<steps;i++){put_f64_le(output,8*i,states[i]);put_f64_le(output,8*(steps+i),times[i]);}
	return (long)required;
}
