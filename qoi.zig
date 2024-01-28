const std = @import("std");

const test_image = @embedFile("QOI-Tests/RRRB.qoi");

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
var test_image_pixels : [test_image_header.image_height][test_image_header.image_width] Pixel = undefined;

// In the enum below, the OP XYZ refers to QOI_OP_XYZ in the specification.
const QOI_OPS = enum(u8) {
    RGB,
    RGBA,
    INDEX,
    DIFF,
    LUMA,
    RUN,
};

pub fn qoi_to_pixels( embedded_qoi_file : [] const u8, comptime iwidth : u32, comptime iheight : u32, pixel_array : *[iheight][iwidth] Pixel ) void {
    // Per the specification,
    // "The decoder and encoder start with {r: 0, g: 0, b: 0, a: 255} as the
    //previous pixel value."

    //    var current_pixel = Pixel{0,0,0,0};
    
    // @question: Does Zig zero-init arrays by default?
    var previously_seen_pixels : [64] Pixel = undefined;
    previously_seen_pixels[0] = Pixel{0,0,0,0};

    var current_byte_index  : usize = 14;
    var current_byte : u8   = undefined;
    var current_pixel_index : usize = 0;

    var current_qoi_op : QOI_OPS = undefined;
    
    while( current_pixel_index < iwidth * iheight) {
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
        
        break; // @temp!
    }
    dprint("Current OP: {any}\n", .{current_qoi_op});
    pixel_array[0][0] = Pixel{1,1,1,1};
}

fn pixel_hash(pixel : Pixel) u8 {
    const r = pixel[0];
    const g = pixel[1];
    const b = pixel[2];
    const a = pixel[3];
    // Using only * will result in a runtime panic: integer overflow
    // To avoid this, we use *% instead. (@thanks tw0st3p!)
    return (r *% 3 + g *% 5 + b *% 7 + a *% 11) % 64;
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



    qoi_to_pixels(test_image, test_image_width, test_image_height, &test_image_pixels);

    dprint("Header: {any}\n", .{test_image_header}); // @debug

}

