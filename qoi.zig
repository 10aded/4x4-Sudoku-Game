const std = @import("std");

const test_image = @embedFile("QOI-Tests/3x4.qoi");

const dprint  = std.debug.print;
const dassert = std.debug.assert;

const Pixel = [4] u8;

const Qoi_Header = struct {
    magic_bytes  : [4] u8,
    image_width  : u32,
    image_height : u32,
    channel      : u8,
    colorspace   : u8,
};

// Note: In Zig DEBUG builds, static memory that are set to undefined are 
// filled with 0xaa s.

pub fn comptime_header_parser( embedded_qoi_file : [] const u8) Qoi_Header {
        // Parse the image header into the qoi_header struct.
    const raw_image = embedded_qoi_file;
    const qoi_header  = Qoi_Header{
        .magic_bytes  = [4]u8{raw_image[0], raw_image[1], raw_image[2], raw_image[3]},
        .image_width  = std.mem.readIntSlice(u32, raw_image[4..8],  .Big), // (Thanks tw0st3p!)
        .image_height = std.mem.readIntSlice(u32, raw_image[8..12], .Big),
        .channel      = raw_image[12],
        .colorspace   = raw_image[13],
    };

    // Check the magic bytes are correct for a .qoi file.
    const magic_bytes_match = std.mem.eql(u8, &qoi_header.magic_bytes, "qoif");
    dassert(magic_bytes_match);
    
    return qoi_header;
}

// TODO: Define these in a more general way.
const test_image_header = comptime_header_parser(test_image);
const test_image_width  = test_image_header.image_width;
const test_image_height = test_image_header.image_height
;
var test_image_pixels : [test_image_header.image_width * test_image_header.image_height] Pixel = undefined;

// In the enum below, the OP XYZ refers to QOI_OP_XYZ in the specification.
const QOI_OPS = enum(u8) {
    RGB,
    RGBA,
    INDEX,
    DIFF,
    LUMA,
    RUN,
};

// @decision: Should this procedure take in a pixel array that is a matrix
// or a simple array... I feel like it should actually just be an array.
pub fn qoi_to_pixels( embedded_qoi_file : [] const u8, comptime number_of_pixels : u64, pixel_array : *[number_of_pixels] Pixel ) void {
    // Per the specification,
    // "The decoder and encoder start with {r: 0, g: 0, b: 0, a: 255} as the
    //previous pixel value."
    var current_pixel = Pixel{0,0,0,255};
    
    // @question: Does Zig zero-init arrays by default?
    var previously_seen_pixels : [64] Pixel = undefined;
    previously_seen_pixels[0] = Pixel{0,0,0,0};

    var current_byte_index  : usize = 14;
    var current_byte : u8   = undefined;
    var current_pixel_index : usize = 0;

    var current_qoi_op : QOI_OPS = undefined;
    
    while( current_pixel_index < number_of_pixels) {
        current_byte = embedded_qoi_file[current_byte_index];
        const bits_67     : u2 = @truncate(current_byte >> 6);
        const bits_012345 : u6 = @truncate(current_byte & 0b00111111);
        current_qoi_op = switch (bits_67) {
            0b00 => .INDEX,
            0b01 => .DIFF,
            0b10 => .LUMA,
            0b11 => switch(bits_012345) {
                0b111110 => .RGB,
                0b111111 => .RGBA,
                else     => .RUN,
            },
        };

        // Calculate the next pixel(s) values, and the index advances.
        var pixel_index_adv : usize = undefined;
        var byte_index_adv  : usize = undefined;
        switch (current_qoi_op) {
            .RGB => {
                // Read a RGB value from the file.
                const red_byte   : u8 = embedded_qoi_file[current_byte_index + 1];
                const green_byte : u8 = embedded_qoi_file[current_byte_index + 2];
                const blue_byte  : u8 = embedded_qoi_file[current_byte_index + 3];
                current_pixel = Pixel{red_byte, green_byte, blue_byte, current_pixel[3]};
                pixel_index_adv = 1;
                byte_index_adv  = 4;
            },
            .RGBA => {
                // Read a RGBA value from the file.
                const red_byte   : u8 = embedded_qoi_file[current_byte_index + 1];
                const green_byte : u8 = embedded_qoi_file[current_byte_index + 2];
                const blue_byte  : u8 = embedded_qoi_file[current_byte_index + 3];
                const alpha_byte : u8 = embedded_qoi_file[current_byte_index + 4];
                current_pixel = Pixel{red_byte, green_byte, blue_byte, alpha_byte}
                ;
                pixel_index_adv = 1;
                byte_index_adv  = 5;
            },
            .INDEX => {
                // Lookup a pixel in previously_seen_pixels, using first six bits
                // of the current byte.
                const index = @as(usize, bits_012345);
                current_pixel = previously_seen_pixels[index];
                pixel_index_adv = 1;
                byte_index_adv  = 1;
            },
            .DIFF => {
                const dr : u2 = @truncate(bits_012345 >> 4);
                const dg : u2 = @truncate(bits_012345 >> 2);
                const db : u2 = @truncate(bits_012345 >> 0); // @bugwatch (!)
                // The specification (regularly) assumes wrapping subtraction,
                // hence the wrapping subtraction here.
                current_pixel = Pixel{current_pixel[0] +% dr -% 2,
                                      current_pixel[1] +% dg -% 2,
                                      current_pixel[2] +% db -% 2,
                                      current_pixel[3]};
                pixel_index_adv = 1;
                byte_index_adv  = 1;
            },
            .LUMA => {
                // Get bits.
                var diff_green : u8 = @as(u8, bits_012345);
                const drdb_byte = embedded_qoi_file[current_byte_index + 1];
                var drdg : u8 = drdb_byte >> 4; // This should be filled with 0s.
                var dbdg : u8 = drdb_byte & 0x0F;
                // Apply offsets.
                diff_green -%= 32;
                drdg       -%= 8;
                dbdg       -%= 8;
                const dg = diff_green;
                const dr = diff_green +% drdg;
                const db = diff_green +% dbdg;
                current_pixel = Pixel{current_pixel[0] +% dr,
                                      current_pixel[1] +% dg,
                                      current_pixel[2] +% db,
                                      current_pixel[3]};
                pixel_index_adv = 1;
                byte_index_adv  = 2;
            },
            .RUN => {
                // Unlike the other OPS, which only write a single
                // pixel, this one writes many (by repeating the value
                // of the current pixel), so the code is a bit different here.
                var run = @as(usize, bits_012345);
                run += 1;

                // Note: Setting this after the loop would mean that
                // the advance is 0, which we don't want. (thanks tw0st3p)!
                pixel_index_adv = run; 
                byte_index_adv  = 1;                

                while (run != 0) : (run -= 1) {
                    pixel_array[run - 1] = current_pixel;
                }
            },
        }
        pixel_array[current_pixel_index] = current_pixel;
        current_pixel_index += pixel_index_adv;
        current_byte_index  += byte_index_adv;
        
        // We don't need to hash when the OP is one of:
        // .RUN
        // .INDEX
        
        // We need to hash a pixel (and store in the previously_seen_pixels)
        // when the OP is one of:
        // .RGB
        // .RGBA
        // .DIFF
        // .LUMA (since the op is 2 bytes, but a INDEX op is just 1 byte)

        // Note: For .DIFF, the specification doesn't say
        // when encoding whether or not .INDEX should have a higher priority
        // than (e.g.) .DIFF
        // As such, hashing a .DIFF result may be reduntant, but we'll choose
        // to do so anyway.
        // This could be because .INDEX should always be chosen if a pixel has
        // been seen before, except in the case of two consecutive INDEXs
        // (in which case a run would be issued instead).

        var hash : u8 = undefined;
        switch(current_qoi_op) {
            .RUN, .INDEX  => {},
            .RGB, .RGBA, .DIFF, .LUMA  => {
                hash = pixel_hash(current_pixel);
                previously_seen_pixels[hash] = current_pixel;
            },
        }
        
        // @debug
        dprint("{any}\n", .{current_pixel});
    }
    dprint("Current OP: {any}\n", .{current_qoi_op});
}

fn pixel_hash(pixel : Pixel) u6 {
    const r = pixel[0];
    const g = pixel[1];
    const b = pixel[2];
    const a = pixel[3];
    // Using only * will result in a runtime panic: integer overflow
    // To avoid this, we use *% instead. (@thanks tw0st3p!)
    const hash : u6 = @truncate(r *% 3 +% g *% 5 +% b *% 7 +% a *% 11);
    return hash;
}

pub fn main() void {
    // TODO: Turn the following into a Zig test
    // Suggestion (tw0st3p:
    // test "test name" { std.testing.expectEqual(@as(u8, 69, foo())) };
    //    const test_pixel_hash = pixel_hash(Pixel{1,1,1,1});
    // Expect: 22
//    const test_pixel_hash = pixel_hash(Pixel{100,0,0,0});
    // Expect: 44
//    dprint("PH: {d}\n", .{test_pixel_hash}); // @debug



    qoi_to_pixels(test_image, @as(u64, test_image_width) * @as(u64, test_image_height), &test_image_pixels);

    dprint("Header: {any}\n", .{test_image_header}); // @debug

}

