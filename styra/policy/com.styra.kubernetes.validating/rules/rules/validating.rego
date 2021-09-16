package policy["com.styra.kubernetes.validating"].rules.rules

import data.global.crossplane.maintenanceWindows
import data.global.crossplane.teamNodeAllocations

enforce[decision] {
  #title: Outside of maintenance window
  #input.request.kind.kind == "ClusterClaim"
  outside_maint_window

  decision := {
    "allowed": false,
    "message": sprintf("Outside of maintenance window (%v)", [input.request.object.metadata.creationTimestamp])
  }
}

enforce[decision] {
  #title: Team has node allocations
  input.request.kind.kind == "ClusterClaim"
  team := input.request.object.metadata.labels["owner-team"]
  not has_key(teamNodeAllocations, team)

  decision := {
    "allowed": false,
    "message": sprintf("Team %v doesn't have any node allocations", [team])
  }
}

enforce[decision] {
  #title: Over maximum allocated nodes
  input.request.kind.kind == "ClusterClaim"
  team := input.request.object.metadata.labels["owner-team"]
  clusterclaims := [
    c |
    cc := data.kubernetes.resources.clusterclaims[_]
    c := cc[_]
  ]

  allNodes := [
    nodes |
    teamClaim := clusterclaims[i].metadata.labels["owner-team"] == team
    nodes := clusterclaims[i].spec.parameters.minNodeCount
  ]

  newNodeCount := sum(allNodes) + input.request.object.spec.parameters.minNodeCount
  newNodeCount > teamNodeAllocations[team]

  decision := {
    "allowed": false,
    "message": sprintf("Number of total nodes (%v) would be over maximum allocated nodes (%v)", [newNodeCount, teamNodeAllocations[team]])
  }
}
enforce[decision] {
  #title: Owner team label must be set
  input.request.kind.kind == "ClusterClaim"
  not input.request.object.metadata.labels["owner-team"]

  decision := {
    "allowed": false,
    "message": "Missing label owner-team"
  }
}

outside_maint_window {
  not inside_maint_window
}

inside_maint_window {
  now := time.parse_rfc3339_ns(input.request.object.metadata.creationTimestamp)
  start := time.parse_rfc3339_ns(maintenanceWindows[i].start)
  end := time.parse_rfc3339_ns(maintenanceWindows[i].end)
  now >= start
  now <= end
}

has_key(x, k) { _ = x[k] }
