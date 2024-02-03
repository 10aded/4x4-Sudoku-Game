// TODO: Write summary of 4 x 4 Sudoku game
//
// Created by 10aded Jan 2024 --- ???
//
// This project was compiled using the Zig compiler (version 0.11.0)
// and built with the command:
//
//     zig build -Doptimize=ReleaseFast
//
// run in the top directory of the project.
//
// The entire source code of this project is available on GitHub at:
//
//   https://github.com/10aded/4x4-Sudoku-Game
//
// and was developed (almost) entirely on the Twitch channel 10aded. Copies of the
// stream are available on YouTube at the @10aded channel.
//
// This project includes a copy of raylib, specifically v5.0 (commit number ae50bfa).
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5a
//
// See the pages above for full license details.


// TODO LIST:
// --[current]--> *  Create textures for the numbers 1..4 using the bitmap.
// *  Think about / implement appropriate buttons (not just rects)
// *  Main menu
// *  Create a place for possible tiles to be dragged
// ** Randomized puzzles (of various degrees of difficulty)
// *  Think about playing game with the keyboard only
// *  Dragging tiles functionality
// *  Comptime ( or even runtime) parsing of puzzle list

const std = @import("std");
const qoi = @import("qoi.zig");
const rl  = @cImport(@cInclude("raylib.h"));

const Vec2   = @Vector(2, f32);
const Pixel = [4] u8;


// Make space to decode the bitmap at comptime.
const bitmap = @embedFile("Bitmap-Stuff/8514-bitmap.qoi");
const bitmap_header = qoi.comptime_header_parser(bitmap);
const bitmap_width  = @as(u64, bitmap_header.image_width);
const bitmap_height = @as(u64, bitmap_header.image_height);

var bitmap_pixels : [bitmap_width * bitmap_height] Pixel = undefined;
var bitmap_bools : [bitmap_width * bitmap_height] bool = undefined;


// Misc. procedures.

const dprint  = std.debug.print;

// Constants
// UI Colors
const BLACK     = rlc(  0,   0,   0);
const DARKGRAY  = rlc( 40,  40,  40);
const LIGHTGRAY = rlc(200, 200, 200);
const WHITE     = rlc(255, 255, 255);

const RED       = rlc(255, 0,   0);
const GREEN     = rlc(0,   255, 0);
const BLUE      = rlc(0,   0,   255);
const YELLOW    = rlc(255, 255, 0);
const MAGENTA   = rlc(255, 0,   255);

const TRANSPARENT = rl.Color{
        .r = 0, .g = 0, .b = 0, .a = 0,
};

const DEBUG  = MAGENTA;


const initial_screen_width = 1902;
const initial_screen_hidth = 1080;
const WINDOW_TITLE = "4x4 Sudoku Game";

// Globals
// Colors
const grid_fill_color = LIGHTGRAY;
const grid_bar_color  = BLACK;

const tile_option_background = LIGHTGRAY;

const background_color = DARKGRAY;

// Game
var gamemode : GameMode = undefined;

// Textures.

var numeral_textures : [4] rl.Texture2D = undefined;

// Mouse
var mouse_down            : bool = undefined;
var mouse_down_last_frame : bool = false;
var mouse_pos             : Vec2 = undefined;

// Screen geometry
var screen_width : f32 = undefined;
var screen_hidth : f32 = undefined;

// Grid Tile Possiblities
// Note: 0 denotes an empty tile
// Positive number represents a fixed tile
// Negative number represents a selected tile.

const Tile = i8;

const Grid = [16] Tile;

const grid1 = Grid{1,2,3,4,
                   4,3,2,1,
                   2,1,4,3,
                   3,4,1,2};

const GameMode =  enum(u8) {
    main_menu,
    puzzles_handcrafted,
    puzzles_randomized,
};

// TODO:
// Write procedure to validate whether or not a given grid is a valid solution.

pub fn main() anyerror!void {

    // Set up RNG.
    // const seed  = std.time.milliTimestamp();
    // prng        = std.rand.DefaultPrng.init(@intCast(seed));

    // Spawn / setup raylib window.    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTargetFPS(144);

    // Import font from embedded file.
//    const merriweather_font = rl.LoadFontFromMemory(".ttf", merriweather_ttf, merriweather_ttf.len, 108, null, 95);

    // button_option_font = merriweather_font;
    // attribution_font   = merriweather_font;
    
//    const random = prng.random();

    gamemode = GameMode.main_menu;

    // @debug


    // Load at runtime the bitmap, and convert to an array of bools.
    qoi.qoi_to_pixels(bitmap, bitmap_width * bitmap_height, &bitmap_pixels);

    for (bitmap_pixels, 0..) |pixel, i| {
        bitmap_bools[i] = pixel[0] == 255;
    }


    // Create a rl.Image s from which to generate the textures containing
    // the bitmap numerals in the game.

    // @magic constant alert!
    // Each character in the bitmap has an x offset that is a multiple of 10.
    // Each has the same height of 20.
    
    var numeral_images : [4] rl.Image = undefined;

    for (0..4) |i| {
        //        numeral_images = rl.GenImageColor(20, 20, TRANSPARENT);
        numeral_images[i] = rl.GenImageColor(20, 20, DEBUG);
    }

    // TODO... transfer bitmap info onto testi using ImageDrawRectangle;    
//    var testi : rl.Image = rl.GenImageColor(5, 5, DEBUG);

//    rl.ImageDrawRectangle(&testi, 1, 1, 2, 2, YELLOW);

    // Initialize the textures for '1', '2', '3', '4'.
    for (0..4) |i| {
        numeral_textures[i] = rl.LoadTextureFromImage(numeral_images[i]);
    }

    //    dprint("{any}\n", .{bitmap_bools}); // @debug
    
    // +----------------+
    // | Main game loop |
    // +----------------+
    while ( ! rl.WindowShouldClose() ) { // Listen for close button or ESC key.

        screen_width = @floatFromInt(rl.GetScreenWidth());
        screen_hidth = @floatFromInt(rl.GetScreenHeight());
        
        process_input_update_state();

        render();
    }
}


fn process_input_update_state() void {
    // Mouse input processing.
    const rl_mouse_pos = rl.GetMousePosition();
    mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

    // Detect button clicks.
    mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    defer mouse_down_last_frame = mouse_down;

    // @temp
    // Change from the main menu to the puzzles when the left mouse is clicked.
    if (mouse_down and ! mouse_down_last_frame) {
        gamemode = GameMode.puzzles_handcrafted;
    }
}


fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(background_color);

    switch(gamemode) {
        .main_menu => {
            render_menu();  
        },
        .puzzles_handcrafted => {
            render_puzzle(grid1);
        },
        .puzzles_randomized => {
            unreachable;
        },
    }
}



// TODO:
// Create an actual main menu.

fn render_menu() void {
    const pos = Vec2{0.5 * screen_width, 0.5 * screen_hidth};
    draw_centered_rect(pos, 100, 100, DEBUG);

    for (0..4) |i| {
        const ii = @as(f32, @floatFromInt(i));
        _ = draw_texture(&numeral_textures[i], Vec2{200 * ii, 200 * ii}, 50);
    }
}

fn render_puzzle(grid : Grid) void {
    const gridpos = Vec2{0.5 * screen_width, 0.4 * screen_hidth};
    // Set sizes of grid elements.
    const minimum_screen_dim = @min(screen_width, screen_hidth);
    const square_length = 0.1  * minimum_screen_dim;
    const bar_thickness = 0.01 * minimum_screen_dim;
    const total_length = 5 * bar_thickness + 4 * square_length;

    // Draw grid background.
    const background_length = total_length - bar_thickness;
    draw_centered_rect(gridpos, background_length, background_length, grid_fill_color);

    // Draw the (non-empty) tiles in the grid.
    // @temp (!!!)
    // 1 |-> red
    // 2 |-> green
    // 3 |-> blue
    // 4 |-> yellow

    const tl_square_pos = gridpos - Vec2{1.5 * ( square_length + bar_thickness), 1.5 * ( square_length + bar_thickness)};
    
    for (grid, 0..) |tile, i| {
        const xi = @as(f32, @floatFromInt(i % 4));
        const yi = @as(f32, @floatFromInt(i / 4));
        const color = switch(tile) {
            1 => RED,
            2 => GREEN,
            3 => BLUE,
            4 => YELLOW,
            else => DEBUG,
        };
        const rect_pos = tl_square_pos + Vec2{xi * (square_length + bar_thickness), yi * (square_length + bar_thickness)};
        const tile_len = square_length + 0.5 * bar_thickness;
        draw_centered_rect(rect_pos, tile_len, tile_len, color);
    }

        // Draw vertical grid bars.
    for (0..5) |i| {
        const offset = @as(f32, @floatFromInt(i)) - 2;
        draw_centered_rect(gridpos + Vec2{offset * (square_length + bar_thickness), 0}, bar_thickness, total_length, grid_bar_color);
        draw_centered_rect(gridpos + Vec2{0, offset * (square_length + bar_thickness)}, total_length, bar_thickness, grid_bar_color);
    }

    // Draw tile options.
    const background_rect_pos = Vec2{0.5 * screen_width, 0.75 * screen_hidth};
    const tile_option_spacing = 0.015 * minimum_screen_dim;
    const background_rect_width  = 4 * square_length + 3 * bar_thickness + 2 * tile_option_spacing;
    const background_rect_height = 1 * square_length +                     2 * tile_option_spacing;
    draw_centered_rect(background_rect_pos, background_rect_width, background_rect_height, tile_option_background);

    const tile_border_thickness = 0.005 * minimum_screen_dim;
    const left_tile_option_pos  = background_rect_pos - Vec2{1.5 * (square_length + bar_thickness), 0};
    
    for (0..4) |i| {
        // TODO: Write a proc which draws an arbitrary tile at an
        // arbitrary position, use this and rewrite the grid drawing code
        // to use it.
        const offset = @as(f32, @floatFromInt(i));

        const tile_pos = left_tile_option_pos + Vec2{offset * (square_length + bar_thickness), 0};
        // @temp!
        const tile_border_length = square_length + tile_border_thickness;
        draw_centered_rect(tile_pos, tile_border_length, tile_border_length, BLACK);
        draw_centered_rect(tile_pos, square_length, square_length, DEBUG);
    }

    // Draw the pixels of the bitmap, by drawing a rectangle for each true value
    // in the bitmap.

    const bitmap_screen_width  = 0.5 * screen_width;
    const bitmap_screen_height = bitmap_screen_width * @as(f32, bitmap_height) / @as(f32, bitmap_width);

    const pixel_square_size = 0.01 * screen_width;
    
    const tl_pixel_corner = Vec2{0.5 * screen_width - 0.5 * bitmap_screen_width, 0.5 * screen_hidth - 0.5 * bitmap_screen_height};
    const tl_pixel_center = tl_pixel_corner + Vec2{0.5 * pixel_square_size, 0.5 * pixel_square_size};
    for (0..bitmap_width) |px| {
        for (0..bitmap_height) |py| {
            const pixel_pos = tl_pixel_center + Vec2{@as(f32,@floatFromInt(px)) * pixel_square_size, @as(f32,@floatFromInt(py)) * pixel_square_size};
            // @prolly should get rid of the if...
            if (bitmap_bools[py * bitmap_width + px]) {
                const pixel_interior_thickness = 0.75;
                draw_centered_rect(pixel_pos, pixel_square_size, pixel_square_size, BLACK);
                draw_centered_rect(pixel_pos, pixel_interior_thickness * pixel_square_size, pixel_interior_thickness * pixel_square_size, WHITE);
            }
        }
    }
        
    
//    draw_centered_rect(.{0.5 * screen_width, 0.5 * screen_hidth}, bitmap_screen_width, bitmap_screen_height, DEBUG); // @debug
}


// Draw a plain (colored) rectangle, where the position determines the center.

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}

fn rlc(r : u8, g : u8, b : u8) rl.Color {
    const rlcolor = rl.Color{
        .r = r,
        .g = g,
        .b = b,
        .a = 255,
    };
    return rlcolor;
}

fn draw_texture(texturep : *rl.Texture2D, center_pos : Vec2 , height : f32 ) f32 {
    const twidth  : f32  = @floatFromInt(texturep.*.width);
    const theight : f32  = @floatFromInt(texturep.*.height);
    
    const scaling_ratio  = height / theight;
    
    const scaled_h  = height;
    const scaled_w  = scaled_h * twidth / theight;
    
    const dumb_rl_tl_vec2 = rl.Vector2{
        .x = center_pos[0] - 0.5 * scaled_w,
        .y = center_pos[1] - 0.5 * scaled_h,
    };

    // The 3rd arg (0) is for rotation.
    rl.DrawTextureEx(texturep.*, dumb_rl_tl_vec2, 0, scaling_ratio, WHITE);
    return scaled_w;
}

fn vec2_to_rl(vec : Vec2) rl.Vector2 {
    const dumb_rl_tl_vec2 = rl.Vector2{
        .x = vec[0],
        .y = vec[1],
    };
    return dumb_rl_tl_vec2;
}
