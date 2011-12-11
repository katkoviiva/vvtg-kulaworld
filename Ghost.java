import processing.core.*;

// pacmanhirviötä ei oikein voi piirtää muuten kun 2d-kuvana
class Ghost extends GameObject {
	PImage texture;
	public Ghost(PVector p, PVector d, PVector u, World w, PApplet pa, PImage tex) {
		super(p, d, u, w, pa, null);
		texture = tex;
	}
	// mörkö kävelee itsekseen eteenpäin
	void update(float dt) {
		super.update(dt);
		if (animation == null) walk(1);
	}
	void render(PGraphics g) {
		g.beginShape();
		g.texture(texture);
		g.vertex(-0.5f, -0.5f, 0,  0, 1);
		g.vertex(0.5f, -0.5f, 0,  1, 1);
		g.vertex(0.5f, 0.5f, 0,  1, 0);
		g.vertex(-0.5f, 0.5f, 0,  0, 0);
		g.endShape();
	}
}
