function createPost()
	parent.healthBar.scale:set(1.75, 1.75)
	parent.healthBar:updateHitbox()
	parent.healthBar.y = parent.healthBar.y - 7;
	parent.healthBar.antialiasing = true
end