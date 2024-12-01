const std = @import("std");
const sys = @import("sys.zig");
pub const UNICODE: bool = true;

test "test GetSystemInfo GetProcessorNum" {
    _ = try sys.GetSystemInfo.init();
    const name = try sys.GetSystemInfo.GetComputerName(sys.GetSystemInfo.c_name_format.PhysicalDnsFullyQualified);
    std.debug.print("name {s}\n", .{name});

    const displaySize = sys.GetSystemInfo.GetDisplayIntegratedDisplaySize();
    std.debug.print("displaySize {}\n", .{displaySize});

    const localTime = sys.GetSystemInfo.GetLocalTime();
    std.debug.print("localTime {d} {d} {d} {d} {d} {d} {d}\n", .{ localTime.wYear, localTime.wMonth, localTime.wDay, localTime.wHour, localTime.wMinute, localTime.wSecond, localTime.wMilliseconds });

    const logicalProcessorInfo = try sys.GetSystemInfo.GetLogicalProcessorInfo(sys.GetSystemInfo.Processor_relationship.All);
    std.debug.print("logicalProcessorInfo {}\n", .{logicalProcessorInfo.Anonymous.Group.ActiveGroupCount});

    const systemInfo = sys.GetSystemInfo.GetNativeSystemInfo();

    std.debug.print("count {d}\n", .{systemInfo.dwNumberOfProcessors});

    std.debug.print("activeProcessorMask {d}\n", .{systemInfo.dwActiveProcessorMask});

    std.debug.print("processortype {d}\n", .{systemInfo.dwProcessorType});

    std.debug.print("processorLevel {d}\n", .{systemInfo.wProcessorLevel});

    std.debug.print("processorRevision {d}\n", .{systemInfo.wProcessorRevision});

    std.debug.print("allocationGranularity {d}\n", .{systemInfo.dwAllocationGranularity});

    std.debug.print("pageSize {d}\n", .{systemInfo.dwPageSize});

    std.debug.print("minimumApplicationAddress {any}\n", .{systemInfo.lpMinimumApplicationAddress});

    std.debug.print("maximumApplicationAddress {any}\n", .{systemInfo.lpMaximumApplicationAddress});

    std.debug.print("processorArchitecture {}\n", .{systemInfo.Anonymous.Anonymous.wProcessorArchitecture});

    std.debug.print("reserved {d}\n", .{systemInfo.Anonymous.Anonymous.wReserved});

    std.debug.print("oemId {d}\n", .{systemInfo.Anonymous.dwOemId});

    const memorygb = sys.GetSystemInfo.GetMemorySpace(.{ .gb = true });
    std.debug.print("memoryall {d}\n", .{memorygb});
    const memorymb = sys.GetSystemInfo.GetMemorySpace(.{ .mb = true });
    std.debug.print("memoryall {d}\n", .{memorymb});
    const memorykb = sys.GetSystemInfo.GetMemorySpace(.{ .kb = true });
    std.debug.print("memoryall {d}\n", .{memorykb});

    const core_0_cycle = sys.GetSystemInfo.GetProcessorCycleTime(0) catch |err| {
        std.debug.print("GetProcessorCycleTime Error {}\n", .{err});
        return;
    };
    std.debug.print("core_0_cycle {d}\n", .{core_0_cycle});

    std.debug.print("test GetSystemInfo GetProcessorNum Success\n", .{});

    const alloc = std.heap.page_allocator;
    const get_sys_folder = try sys.GetSystemInfo.GetSystemDirectory();
    defer alloc.free(get_sys_folder);
    std.debug.print("GetSystemDirectory {s}\n", .{get_sys_folder});

    const get_windows_folder = try sys.GetSystemInfo.GetWindowsDirectory();
    defer alloc.free(get_windows_folder);
    std.debug.print("GetWindowsDirectory {s}\n", .{get_windows_folder});

    const get_sys_time = sys.GetSystemInfo.GetSystemTime();
    std.debug.print("GetSystemTime {d} {d} {d} {d} {d} {d} {d}\n", .{ get_sys_time.wYear, get_sys_time.wMonth, get_sys_time.wDay, get_sys_time.wHour, get_sys_time.wMinute, get_sys_time.wSecond, get_sys_time.wMilliseconds });
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
