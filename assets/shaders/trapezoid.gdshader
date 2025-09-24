shader_type canvas_item;

uniform float level = 0.5; // skewness / angle

void vertex() {
	VERTEX.x -= VERTEX.y * level;
}