const std    = @import("std");
const builtin = @import("builtin");

const CSourceFile = std.Build.Module.CSourceFile;
const LazyPath    = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});

	const optimize = b.standardOptimizeOption(.{});

	const exe = b.addExecutable(.{
		.name = "4x4-Sudoku",
		.root_source_file = .{ .path = "main.zig" },
		.target = target,
		.optimize = optimize,
	});

	b.installArtifact(exe);

    const raylib = addRaylib(b, target, optimize, false);

    exe.addIncludePath(LazyPath.relative("./Raylib5/src"));
	exe.linkLibrary(raylib);

	const run_cmd = b.addRunArtifact(exe);

	run_cmd.step.dependOn(b.getInstallStep());

	if (b.args) |args| {
		run_cmd.addArgs(args);
	}

	const run_step = b.step("run", "run the game");
	run_step.dependOn(&run_cmd.step);
}

// The function below is a modified (and simplified) version of `build.zig` included as part of the standard Raylib5 distribution in src/build.zig.
// As such it (presumably) has the same licence as the rest of raylib.
pub fn addRaylib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, platform_drm : bool) *std.Build.Step.Compile {
    const raylib_flags = [_][]const u8{
        "-std=gnu99",
        "-D_GNU_SOURCE",
        "-DGL_SILENCE_DEPRECATION=199309L",
    };

    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });
    raylib.linkLibC();

    // No GLFW required on PLATFORM_DRM
    // DRM means Direct Rendering Manager.
    if (!platform_drm) {
        const external_glfw_include = LazyPath.relative("./Raylib5/src/external/glfw/include");
        raylib.addIncludePath(external_glfw_include);
    }

    // Raylib C files to add.
    // TODO: Update to remove 0.12.0 compiler warning.
    const rcore_path     = LazyPath.relative("./Raylib5/src/rcore.c");
    const utils_path     = LazyPath.relative("./Raylib5/src/utils.c");
    const rshapes_path   = LazyPath.relative("./Raylib5/src/rshapes.c");
    const rtext_path     = LazyPath.relative("./Raylib5/src/rtext.c");
    const rtextures_path = LazyPath.relative("./Raylib5/src/rtextures.c");

    // The game does not call neither audio nor model procedures.
    //    const raudio_path    = LazyPath.relative("./Raylib5/src/raudio.c");
    //    const rmodels_path   = LazyPath.relative("./Raylib5/src/rmodels.c");
    
    // Note: adding rmodels in the default raylib build.zig file turns off clang's
    // turns of one of the sanitizers via -fno-sanitize=undefined, this was
    // accompanied by a GitHub raylib issue, but the issue has now been closed. As
    // such we'll just import it as usual.

    // Note: Even though we (seemingly) do not directly call functions in rtext, not
    // importing this leads to a compile error.
    
    raylib.addCSourceFile(CSourceFile{.file = rcore_path,     .flags = &raylib_flags});
    raylib.addCSourceFile(CSourceFile{.file = utils_path,     .flags = &raylib_flags});
    raylib.addCSourceFile(CSourceFile{.file = rshapes_path,   .flags = &raylib_flags});
    raylib.addCSourceFile(CSourceFile{.file = rtext_path,     .flags = &raylib_flags});
    raylib.addCSourceFile(CSourceFile{.file = rtextures_path, .flags = &raylib_flags});

    //    raylib.addCSourceFile(CSourceFile{.file = raudio_path,    .flags = &raylib_flags});
    //    raylib.addCSourceFile(CSourceFile{.file = rmodels_path,   .flags = &raylib_flags});
    
    const rglfw_path = LazyPath.relative("./Raylib5/src/rglfw.c");
    
    switch (target.result.os.tag) {
        .windows => {
            raylib.addCSourceFile(CSourceFile{.file = rglfw_path, .flags = &raylib_flags});
            raylib.linkSystemLibrary("winmm");
            raylib.linkSystemLibrary("gdi32");
            raylib.linkSystemLibrary("opengl32");
            raylib.addIncludePath(.{ .path = "external/glfw/deps/mingw" });

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .linux => {
            if (!platform_drm) {
                raylib.addCSourceFile(CSourceFile{.file = rglfw_path, .flags = &raylib_flags});
                raylib.linkSystemLibrary("GL");
                raylib.linkSystemLibrary("rt");
                raylib.linkSystemLibrary("dl");
                raylib.linkSystemLibrary("m");
                raylib.linkSystemLibrary("X11");
                raylib.addLibraryPath(.{ .path = "/usr/lib" });
                raylib.addIncludePath(.{ .path = "/usr/include" });

                raylib.defineCMacro("PLATFORM_DESKTOP", null);
            } else {
                raylib.linkSystemLibrary("GLESv2");
                raylib.linkSystemLibrary("EGL");
                raylib.linkSystemLibrary("drm");
                raylib.linkSystemLibrary("gbm");
                raylib.linkSystemLibrary("pthread");
                raylib.linkSystemLibrary("rt");
                raylib.linkSystemLibrary("m");
                raylib.linkSystemLibrary("dl");
                raylib.addIncludePath(.{ .path = "/usr/include/libdrm" });

                raylib.defineCMacro("PLATFORM_DRM", null);
                raylib.defineCMacro("GRAPHICS_API_OPENGL_ES2", null);
                raylib.defineCMacro("EGL_NO_X11", null);
                raylib.defineCMacro("DEFAULT_BATCH_BUFFER_ELEMENT", "2048");
            }
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            raylib.addCSourceFile(CSourceFile{.file = rglfw_path, .flags = &raylib_flags});
            raylib.linkSystemLibrary("GL");
            raylib.linkSystemLibrary("rt");
            raylib.linkSystemLibrary("dl");
            raylib.linkSystemLibrary("m");
            raylib.linkSystemLibrary("X11");
            raylib.linkSystemLibrary("Xrandr");
            raylib.linkSystemLibrary("Xinerama");
            raylib.linkSystemLibrary("Xi");
            raylib.linkSystemLibrary("Xxf86vm");
            raylib.linkSystemLibrary("Xcursor");

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .macos => {
            // On macos rglfw.c include Objective-C files.
            const raylib_flags_extra_macos = &[_][]const u8{
                "-ObjC",
            };
            raylib.addCSourceFile(CSourceFile{.file = rglfw_path, .flags = &raylib_flags ++ raylib_flags_extra_macos});            
            
            raylib.linkFramework("Foundation");
            raylib.linkFramework("CoreServices");
            raylib.linkFramework("CoreGraphics");
            raylib.linkFramework("AppKit");
            raylib.linkFramework("IOKit");

 raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .emscripten => {
            raylib.defineCMacro("PLATFORM_WEB", null);
            raylib.defineCMacro("GRAPHICS_API_OPENGL_ES2", null);

            if (b.sysroot == null) {
                @panic("Pass '--sysroot \"$EMSDK/upstream/emscripten\"'");
            }

            const cache_include = std.fs.path.join(b.allocator, &.{ b.sysroot.?, "cache", "sysroot", "include" }) catch @panic("Out of memory");
            defer b.allocator.free(cache_include);

            var dir = std.fs.openDirAbsolute(cache_include, std.fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = true }) catch @panic("No emscripten cache. Generate it!");
            dir.close();

            raylib.addIncludePath(.{ .path = cache_include });
        },
        else => {
            @panic("Unsupported OS");
        },
    }

    return raylib;
}
