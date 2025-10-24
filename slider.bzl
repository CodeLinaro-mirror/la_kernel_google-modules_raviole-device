# SPDX-License-Identifier: GPL-2.0

"""A central location to put build constants / macros for compiling the slider kernel.
"""

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//common:bazel/modules.bzl", "get_gki_modules_list")

SLIDER_MODULE_OUTS = [
    # keep sorted
    "drivers/hwtracing/coresight/coresight.ko",
    "drivers/hwtracing/coresight/coresight-etm4x.ko",
    "drivers/hwtracing/coresight/coresight-funnel.ko",
    "drivers/hwtracing/coresight/coresight-replicator.ko",
    "drivers/hwtracing/coresight/coresight-tmc.ko",
    "drivers/i2c/i2c-dev.ko",
    "drivers/misc/eeprom/at24.ko",
    "drivers/perf/arm_dsu_pmu.ko",
    "drivers/pps/clients/pps-gpio.ko",
    "drivers/scsi/sg.ko",
    "drivers/spi/spidev.ko",
    "drivers/watchdog/softdog.ko",
    "net/core/pktgen.ko",
    "net/mac80211/mac80211.ko",
    "net/wireless/cfg80211.ko",
]

# List of GKI modules to omit
_SLIDER_GKI_MODULES_EXCLUDE = [
    "arch/arm64/geniezone/gzvm.ko",
    "drivers/ptp/ptp_kvm.ko",
]

def _vendor_dlkm_gki_modules_list_map_each(m):
    if m in _SLIDER_GKI_MODULES_EXCLUDE:
        return None
    return "^kernel/" + m

def _slider_vendor_dlkm_modules_list_impl(
        name,
        **kwargs):
    in_tree_modules = get_gki_modules_list(
        "arm64",
        map_each = _vendor_dlkm_gki_modules_list_map_each,
    )
    in_tree_modules += ["^kernel/" + m for m in SLIDER_MODULE_OUTS]

    write_file(
        name = "slider_vendor_dlkm_modules_list",
        out = "slider_vendor_dlkm_modules",
        content = in_tree_modules + [
            # Add all external modules
            "^extra/.*",
        ],
        **kwargs
    )

slider_vendor_dlkm_modules_list = macro(
    implementation = _slider_vendor_dlkm_modules_list_impl,
)

def _dist_gki_modules_map_each(m):
    if m in _SLIDER_GKI_MODULES_EXCLUDE:
        return None
    return "//common:kernel_aarch64/" + m

SLIDER_DIST_GKI_MODULES = get_gki_modules_list(
    "arm64",
    map_each = _dist_gki_modules_map_each,
)
