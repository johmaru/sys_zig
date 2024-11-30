const std = @import("std");
const sys = @import("sys.zig");
pub const UNICODE: bool = true;

test "test GetSystemInfo GetProcessorNum" {
    _ = try sys.GetSystemInfo.init();
    std.debug.print("count {d}\n", .{sys.GetSystemInfo.GetProcessorNum()});
    const name = try sys.GetSystemInfo.GetComputerName(sys.GetSystemInfo.c_name_format.PhysicalDnsFullyQualified);
    std.debug.print("name {s}\n", .{name});
    std.debug.print("test GetSystemInfo GetProcessorNum Success", .{});
}

test "test window" {
    _ = try sys.GetWindow.init();
    try sys.GetWindow.addText(0, 0, "test");
    try sys.GetWindow.addText(0, 20, "test2");
    var thread = try sys.GetWindow.ShowWindow();
    defer thread.join();

    std.time.sleep(100 * std.time.ns_per_ms);
    try sys.GetWindow.ShutdownWindow();
}
