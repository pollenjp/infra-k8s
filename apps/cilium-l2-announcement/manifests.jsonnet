local name = (import 'config.json5').name;

local cilium_balancer_ip_pool = {
  apiVersion: "cilium.io/v2alpha1",
  kind: "CiliumLoadBalancerIPPool",
  metadata: {
    name: 'dummy',
  },
  spec: {
    blocks: [{ start: "192.168.100.80", stop: "192.168.100.89" }],
  },
};
local cilium_balancer_ip_pool_name = name + '-ip-pool-' + (import '../../jsonnetlib/hash.libsonnet') {data: cilium_balancer_ip_pool}.output;

local cilium_l2_announcement = {
  apiVersion: "cilium.io/v2alpha1",
  kind: "CiliumL2AnnouncementPolicy",
  metadata: {
    name: 'dummy',
  },
  spec: {
    nodeSelector: {
      matchExpressions: [
        { key: "node-role.kubernetes.io/control-plane", operator: "DoesNotExist" },
      ],
    },
    interfaces: ["^eth[0-9]+"],
    externalIPs: true,
    loadBalancerIPs: true,
  },
};
local cilium_l2_announcement_name = name + '-l2-announcement-policy-' + (import '../../jsonnetlib/hash.libsonnet') {data: cilium_l2_announcement}.output;

[
  std.mergePatch(cilium_balancer_ip_pool, { metadata: { name: cilium_balancer_ip_pool_name } }),
  std.mergePatch(cilium_l2_announcement, { metadata: { name: cilium_l2_announcement_name } }),
]
