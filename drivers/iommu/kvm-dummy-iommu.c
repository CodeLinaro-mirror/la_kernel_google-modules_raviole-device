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

static void kvm_dummy_iommu_remove(void)
{
}

static int kvm_dummy_iommu_id(struct device *dev, u32 id, pkvm_handle_t *out_iommu, u32 *out_sid)
{
	return 0;
}

static pkvm_handle_t kvm_dummy_iommu_id_by_of(struct device_node *np)
{
	return 0;
}

struct kvm_iommu_driver kvm_smmu_v3_ops = {
	.init_driver = kvm_dummy_iommu_init,
	.remove_driver = kvm_dummy_iommu_remove,
	.get_device_iommu_id = kvm_dummy_iommu_id,
	.get_iommu_id_by_of = kvm_dummy_iommu_id_by_of,
};

static int kvm_dummy_iommu_register(void)
{
	return kvm_iommu_register_driver(&kvm_smmu_v3_ops);
}

/*
 * Register must be run before de-privilege and before kvm_iommu_init_driver.
 * Only pKVM early loading will load it early enough.
 */
module_init(kvm_dummy_iommu_register);

MODULE_LICENSE("GPL v2");
