module hill_cipher_mod26_java;

fn long hill_cipher_mod26_java(long* input, usz length, char* output, usz capacity) @export("hill_cipher_mod26_java") {
	if(input==null||length<1||length>257||(input[0]!=0&&input[0]!=1))return -1;
	long key[4];
	if(input[0]==0){key[0]=3;key[1]=3;key[2]=2;key[3]=5;}else{key[0]=15;key[1]=17;key[2]=20;key[3]=9;}
	char text[256];usz text_length=0;
	for(usz i=1;i<length;i++){
		if(input[i]<0||input[i]>127)return -1;
		long c=input[i];if(c>='a'&&c<='z')c-='a'-'A';if(c>='A'&&c<='Z')text[text_length++]=(char)c;
	}
	if(text_length%2==1)text[text_length++]='X';
	if(text_length>capacity||(text_length>0&&output==null))return -2;
	for(usz i=0;i<text_length;i+=2){long a=text[i]-'A',b=text[i+1]-'A';output[i]=(char)('A'+(key[0]*a+key[1]*b)%26);output[i+1]=(char)('A'+(key[2]*a+key[3]*b)%26);}
	return (long)text_length;
}
