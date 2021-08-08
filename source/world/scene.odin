package world

import "../system"
import "../graphics"

Scene :: struct {
	renderer: graphics.SpriteRenderer,
	camera: graphics.Camera,
}