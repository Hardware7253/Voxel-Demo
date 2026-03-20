extends Node

# Rotates a node to match the direction of the node_alignment_dir to match_dir
# Leaves the node unrotated if it's alignment vector is parallel to the match vector
# Directions are expected to be unit vectors
func rotate_to_match_dir(node: Node3D, node_alignment_dir: Vector3, match_dir: Vector3):
	var angle = acos(node_alignment_dir.dot(match_dir)) # From θ = cos⁻¹((a·b) / (|a||b|))
	var axis = node_alignment_dir.cross(match_dir)
	if axis.length() > 0.000001:
		node.basis = Basis(axis.normalized(), angle)
	else:
		node.basis = Basis.IDENTITY

