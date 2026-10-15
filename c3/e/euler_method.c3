module euler_method;

fn void put_f64_le(char* output, usz offset, double value) {
	ulong bits = @bitcast(ulong, value);
	for (usz byte = 0; byte < 8; byte++) output[offset+byte] = (char)((bits >> (8*byte)) & 255);
}

fn long euler_method(long* input, usz length, char* output, usz capacity) @export("euler_method") {
	if (input==null || length!=4 || input[0]<-8 || input[0]>8 || input[1]<-8 || input[1]>8 || input[2]<1 || input[2]>4 || input[3]<1 || input[3]>16) return -1;
	usz steps=(usz)input[3],required=8*(steps+1);
	if(output==null||capacity<required)return -2;
	double h=1.0;for(long bit=0;bit<input[2];bit++)h/=2.0;
	double x=(double)input[0],y=(double)input[1];put_f64_le(output,0,y);
	for(usz step=0;step<steps;step++){y=y+h*(x+y);x+=h;put_f64_le(output,8*(step+1),y);}
	return (long)required;
}
