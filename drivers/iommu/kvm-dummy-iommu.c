// SPDX-License-Identifier: GPL-2.0
/*
 * pKVM dummy IOMMU host driver
 *
 * Copyright (C) 2024 Google LLC
 * Author: Keir Fraser <keirf@google.com>
 */

#include <asm/kvm_pkvm.h>
#include <asm/kvm_mmu.h>
#include <linux/kvm_host.h>
#include <linux/moduleparam.h>

static int kvm_dummy_iommu_init(void)
{
	kvm_err("pKVM enabled with dummy IOMMU driver, do not run confidential" \
		" workloads in virtual machines\n");
	return 0;
}

struct kvm_iommu_driver kvm_smmu_v3_ops = {
	.init_driver = kvm_dummy_iommu_init,
};

static int kvm_dummy_iommu_register(void)
{
	return kvm_iommu_register_driver(&kvm_smmu_v3_ops, 0);
}

/*
 * Register must be run before de-privilege and before kvm_iommu_init_driver.
 * Only pKVM early loading will load it early enough.
 */
module_init(kvm_dummy_iommu_register);

MODULE_LICENSE("GPL v2");
