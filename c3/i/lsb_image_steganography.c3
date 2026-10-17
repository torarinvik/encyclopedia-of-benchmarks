module lsb_image_steganography;

fn long lsb_image_steganography(long* input, usz length, char* output, usz output_capacity) @export("lsb_image_steganography") {
    if(input==null||length<3||length>292)return -1;
    if(input[0]<1||input[0]>16||input[1]<1||input[1]>16||input[2]<0||input[2]>32)return -1;
    usz rows=(usz)input[0],columns=(usz)input[1],message_length=(usz)input[2];
    usz pixel_count=rows*columns;
    if(message_length*8>pixel_count||length!=3+pixel_count+message_length)return -1;
    for(usz i=0;i<pixel_count;i++)if(input[3+i]<0||input[3+i]>254)return -1;
    for(usz i=0;i<message_length;i++)if(input[3+pixel_count+i]<0||input[3+pixel_count+i]>127)return -1;
    if(output==null||output_capacity<pixel_count)return -2;
    for(usz i=0;i<pixel_count;i++)output[i]=(char)input[3+i];
    usz bit_index=0;
    for(usz i=0;i<message_length;i++){
        uint byte=(uint)input[3+pixel_count+i];
        for(int shift=7;shift>=0;shift--){
            uint bit=(byte>>(uint)shift)&1;
            uint pixel=(uint)input[3+bit_index];
            output[bit_index]=(char)(pixel+((pixel&1)^bit));
            bit_index++;
        }
    }
    return (long)pixel_count;
}
