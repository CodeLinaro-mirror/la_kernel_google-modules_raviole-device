// SPDX-License-Identifier: GPL-2.0
/*
 * Clock Trace Tracing Integration
 *
 * Copyright (C) 2025 Google, Inc.
 */

#include <linux/module.h>

#define CREATE_TRACE_POINTS
#include <trace/events/clock.h>

EXPORT_TRACEPOINT_SYMBOL_GPL(clock_set_rate);

static __init int clocktrace_init(void)
{
	return 0;
}

static __exit void clocktrace_exit(void)
{
}

module_init(clocktrace_init);
module_exit(clocktrace_exit);

MODULE_AUTHOR("Peter Griffin <gpeter@google.com>");
MODULE_DESCRIPTION("Clock Trace Driver");
MODULE_LICENSE("GPL");
