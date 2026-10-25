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
const MIN_SIDE: usize = 15;
const MAX_SIDE: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MASK_RADIUS: isize = 7;

fn reflect_index(index: isize, side: usize) -> usize {
    if index < 0 { (-index - 1) as usize }
    else if index >= side as isize { (2 * side as isize - index - 1) as usize }
    else { index as usize }
}

fn setup_weights() -> ([i32; 511], [i32; 225]) {
    let mut brightness = [0_i32; 511];
    for difference in -255..=255 {
        let mut temp = difference as f32 / 20.0_f32;
        temp *= temp;
        temp = (100.0_f64 * (-f64::from(temp)).exp()) as f32;
        brightness[(difference + 255) as usize] = temp as i32;
    }
    let mut distance = [0_i32; 225];
    let mut index = 0;
    for dy in -MASK_RADIUS..=MASK_RADIUS {
        for dx in -MASK_RADIUS..=MASK_RADIUS {
            let squared_distance = (dx * dx + dy * dy) as f32;
            distance[index] = (100.0_f64 * (f64::from(squared_distance) / -16.0_f64).exp()) as i32;
            index += 1;
        }
    }
    (brightness, distance)
}

fn median_eight(image: &[u8; 256], side: usize, y: usize, x: usize) -> u8 {
    let mut values = [0_u8; 8];
    let mut count = 0;
    for dy in -1..=1 {
        for dx in -1..=1 {
            if dx == 0 && dy == 0 { continue; }
            let sy = reflect_index(y as isize + dy, side);
            let sx = reflect_index(x as isize + dx, side);
            values[count] = image[sy * side + sx];
            count += 1;
        }
    }
    values.sort_unstable();
    ((u16::from(values[3]) + u16::from(values[4])) / 2) as u8
}

#[no_mangle]
pub unsafe extern "C" fn mibench_automotive_susan(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    if input[0] < MIN_SIDE as i64 || input[0] > MAX_SIDE as i64 { return -1; }
    let side = input[0] as usize;
    let pixel_count = side * side;
    if input_length != pixel_count + 1 { return -1; }
    let mut image = [0_u8; 256];
    for index in 0..pixel_count {
        let pixel = input[index + 1];
        if !(0..=255).contains(&pixel) { return -1; }
        image[index] = pixel as u8;
    }
    if output.is_null() || output_capacity < pixel_count { return -2; }

    let (brightness, distance) = setup_weights();
    for y in 0..side {
        for x in 0..side {
            let center = i32::from(image[y * side + x]);
            let mut area = 0_i32;
            let mut total = 0_i32;
            let mut mask_index = 0;
            for dy in -MASK_RADIUS..=MASK_RADIUS {
                let sy = reflect_index(y as isize + dy, side);
                for dx in -MASK_RADIUS..=MASK_RADIUS {
                    let sx = reflect_index(x as isize + dx, side);
                    let pixel = i32::from(image[sy * side + sx]);
                    let contribution = distance[mask_index] * brightness[(center - pixel + 255) as usize];
                    area += contribution;
                    total += contribution * pixel;
                    mask_index += 1;
                }
            }
            let denominator = area - 10000;
            let value = if denominator == 0 {
                median_eight(&image, side, y, x)
            } else {
                ((total - center * 10000) / denominator) as u8
            };
            *output.add(y * side + x) = value;
        }
    }
    pixel_count as i64
}
