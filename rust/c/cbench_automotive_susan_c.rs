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
const MAX_NO_CORNERS: i32 = 1850;
const MASK_X: [i32; 36] = [-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1];
const MASK_Y: [i32; 36] = [-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3];

fn brightness_table() -> [u8; 513] {
    let mut table = [0u8; 513];
    for difference in -256i32..=256 {
        let scaled = f64::from(difference.abs()) / 20.0;
        let term = scaled * scaled;
        let term = term * term * term;
        table[(difference + 256) as usize] = (100.0 * (-term).exp()) as u8;
    }
    table
}
fn ftoi(value: f32) -> i32 { if value < 0.0 { (f64::from(value) - 0.5) as i32 } else { (f64::from(value) + 0.5) as i32 } }
fn is_local_corner(response: &[i32; 256], side: usize, y: i32, x: i32) -> bool {
    let value = response[(y as usize) * side + x as usize];
    for dy in -3..=3 { for dx in -3..=3 {
        if dx == 0 && dy == 0 { continue; }
        let neighbour = response[((y + dy) as usize) * side + (x + dx) as usize];
        if dy < 0 || (dy == 0 && dx < 0) { if value <= neighbour { return false; } }
        else if value < neighbour { return false; }
    } }
    true
}
fn susan_corners(image: &mut [u8; 256], side: usize, brightness: &[u8; 513]) {
    let mut response = [0i32; 256];
    let mut gradient_x = [0i32; 256];
    let mut gradient_y = [0i32; 256];
    let mut points_x = [0i32; 256];
    let mut points_y = [0i32; 256];
    let mut point_count = 0usize;
    for y in 5i32..(side as i32 - 5) { for x in 5i32..(side as i32 - 5) {
        let center = image[y as usize * side + x as usize] as i32;
        let mut area = 100;
        for k in 0..36 { let pixel = image[((y + MASK_Y[k]) as usize) * side + (x + MASK_X[k]) as usize] as i32; area += brightness[(center - pixel + 256) as usize] as i32; }
        if area >= MAX_NO_CORNERS { continue; }
        let mut gx = 0; let mut gy = 0;
        for k in 0..36 { let pixel = image[((y + MASK_Y[k]) as usize) * side + (x + MASK_X[k]) as usize] as i32; let weight = brightness[(center - pixel + 256) as usize] as i32; gx += MASK_X[k] * weight; gy += MASK_Y[k] * weight; }
        let xx = gx * gx; let yy = gy * gy;
        if xx + yy <= area * area / 2 { continue; }
        let mut along = 0;
        if yy < xx {
            let divide = (gy as f32) / (gx.abs() as f32);
            let step_x = gx.abs() / gx;
            for distance in 1..=3 { let row = y + ftoi((distance as f32) * divide); let col = x + distance * step_x; along += brightness[(center - image[row as usize * side + col as usize] as i32 + 256) as usize] as i32; }
        } else {
            let divide = (gx as f32) / (gy.abs() as f32);
            let step_y = gy.abs() / gy;
            for distance in 1..=3 { let row = y + distance * step_y; let col = x + ftoi((distance as f32) * divide); along += brightness[(center - image[row as usize * side + col as usize] as i32 + 256) as usize] as i32; }
        }
        if along > 290 { let at = y as usize * side + x as usize; response[at] = MAX_NO_CORNERS - area; gradient_x[at] = 51 * gx / area; gradient_y[at] = 51 * gy / area; }
    } }
    for y in 5i32..(side as i32 - 5) { for x in 5i32..(side as i32 - 5) { let at = y as usize * side + x as usize; if response[at] > 0 && is_local_corner(&response, side, y, x) { points_x[point_count]=x;points_y[point_count]=y;point_count+=1; } } }
    for point in 0..point_count { let x=points_x[point] as usize;let y=points_y[point] as usize;let at=(y-1)*side+x-1;image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=0;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255; }
    let _ = (gradient_x, gradient_y);
}

#[no_mangle]
pub unsafe extern "C" fn cbench_automotive_susan_c(input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let side_value = *input;
    if !(MIN_SIDE..=MAX_SIDE).contains(&side_value) { return -1; }
    let side = side_value as usize; let count = side * side;
    if input_length != count + 1 { return -1; }
    let mut image = [0u8; 256];
    for index in 0..count { let pixel = *input.add(index + 1); if !(0..=255).contains(&pixel) { return -1; } image[index] = pixel as u8; }
    if output.is_null() || output_capacity < count { return -2; }
    let brightness = brightness_table(); susan_corners(&mut image, side, &brightness);
    for index in 0..count { *output.add(index) = image[index]; }
    count as i64
}
