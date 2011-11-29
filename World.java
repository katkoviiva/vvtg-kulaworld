import processing.core.*;

public class World {
	int size, size3;
	int[] map;
	//int space=2;
	World(PApplet pa, int sz) {
		size = sz;
		size3 = sz * sz * sz;
		map = new int[size3];
		new PrimMap(this, pa);
	}
	boolean hasBlk(PVector point) {
		int x = PApplet.round(point.x); // round
		int y = PApplet.round(point.y);
		int z = PApplet.round(point.z);
		//println("has? " + point.x + " " + point.y + " " + point.z);
		return x >= 0 && y >= 0 && z >= 0 
			&& x < size && y < size && z < size 
			&& map[at(x, y, z)] != 0;
	}
	int at(int x, int y, int z) {
		return at(x, y, z, size);
	}
	int at(int x, int y, int z, int size) {
		return size * (size * z + y) + x;
	}
	void draw(PApplet pa) {
		pa.pushMatrix();
		for (int z = 0; z < size; z++) {
			for (int y = 0; y < size; y++) {
				for (int x = 0; x < size; x++) {
					dobox(pa, x, y, z);
				}
			}
		}
		pa.popMatrix();
	}
	void dobox(PApplet pa, int x, int y, int z) {
		int colo = map[size * size * z + size * y + x];
		//println(colo);
		if (colo == 0) return;
		//PVector bottomidx = PVector.add(player.pos, PVector.mult(player.up, -1));
		//if (x == round(bottomidx.x) && y == round(bottomidx.y) && z == round(bottomidx.z)) colo = color(255, 255, 255, 250);
		//else 
		colo = (colo & 0xffffff) | 0x7f000000;
		pa.pushMatrix();
		pa.translate(x, y, z);
		pa.fill(colo);
		pa.texture(boxtex);
		TexCube t = new TexCube();
		t.draw(pa, boxtex, 0.5f);
// 		tcube.draw(0.5);
// 		pa.box(1);
		pa.popMatrix();
	}
	
	void visit(PVector point) {
		int x = PApplet.round(point.x); // round
		int y = PApplet.round(point.y);
		int z = PApplet.round(point.z);
		map[at(x, y, z)] = 0xffffffff;
	}
	PImage boxtex;
	void boxTex(PImage tex) { boxtex = tex; }
}


// prim's algorithm / pienin virittäjäpuu
// harvassa pisteitä, joista jokaisesta pääsee jotenkin jonnekin
// jokseenkin mielekäs kartta testailuun

// kartan vokseleitä käpistellään indeksillä eikä (x,y,z)-kolmikolla
// ehkä vähän hankalaa näin päin kumminkin
class PrimMap {
	World world;
	int size, size3;
	int[] map; // kartassa on värit, 0 jos ei palikkaa
	PrimMap(World world, PApplet pa) {
		size = world.size;
		size3 = world.size3;
		this.world = world;
		generate(pa);
	}
	void generate(PApplet pa) {
		// kulkuväylän leveys, ei mielellään 0
		int space = 6;
		// sz^3 pisteitä, joiden välillä space tyhjää (tyhjä 0: kuutio)
		// eli (sz + (sz - 1) * space) ^ 3 tileä
		// visited ~ V_new
		
		boolean[] visited = new boolean[size3];
		int[] visitorder = new int[size3]; // indeksoidaan järjestysnumerolla
		
		// aluksi size on pisteiden määrä, newsize sitten kun niiden väliin on venytetty kulkuväyliä
		int newsz = size + (size - 1) * space;
		int newsz3 = newsz * newsz * newsz;
		map = new int[newsz3];
		
		// lähtöpaikka
		visitorder[0] = 0;
		visited[0] = true;
		map[0] = 0xffffffff;
		
		// käydään kaikki alkuperäiset pisteet läpi, jokaiseen mennään jotenkin
		for (int count = 1; count < size3; count++) {
			// - arvo tiili reunalta
			// (randomilla saattaa tulla sellainenkin joka ei ole reunalla, ei väliä kun ei jättikarttoja)
			// vois tietty pitää listaa sellaisista joista ei vielä pääse kaikkialle...
			// - arvo sille suunta
			// - visitoi se.
			int vidx;
			do {
				vidx = (int)(pa.random(0, count)); // monesko jo visitoitu leviää.
			} while (full(visited, visitorder[vidx]));
			
			int idx = visitorder[vidx];
			int z = idx / (size * size), y = idx / size % size, x = idx % size;
			
			// joku vierestä, dir on akselin suuntainen yksikkövektori
			int[] dir = getadj(pa, x, y, z, visited);
			int nx = x + dir[0], ny = y + dir[1], nz = z + dir[2];
			int newidx = world.at(nx, ny, nz);

			visitorder[count] = newidx;
			visited[newidx] = true;
			
			// nykykohta venytetyssä maailmassa
			int i = x * (space + 1), j = y * (space + 1), k = z * (space + 1);
			
// 			map[world.at(nx*(space+1), ny*(space+1), nz*(space+1), newsz)] = pa.color(255, 0, 0);
			
			// nurkkien välillä debugväreillä
			for (int a = 0; a < space; a++) {
				i += dir[0];
				j += dir[1];
				k += dir[2];
				// vihreä kasvaa iteraatioiden kasvaessa, sininen taas z:n mukaan
				map[world.at(i, j, k, newsz)] = pa.color(1, (int)((float)count / size3 * 255), (int)((float)k/newsz*255));
			}
			// verkon kärkipisteet punaisia
			map[world.at(i + dir[0], j + dir[1], k + dir[2], newsz)] = pa.color(255, 0, 0);
		}
		
		world.size = newsz;
		world.size3 = newsz3;
		world.map = map;
	}
	boolean full(boolean[] visited, int i) {
		return full(visited, i % size, i / size % size, i / (size * size));
	}
	// full == tästä ei pääse enää mihinkään uuteen paikkaan
	boolean full(boolean[] visited, int x, int y, int z) {
		return (x == 0 ? true : visited[world.at(x-1, y, z)])
			&& (x == size-1 ? true : visited[world.at(x+1, y, z)])
			&& (y == 0 ? true : visited[world.at(x, y-1, z)])
			&& (y == size-1 ? true : visited[world.at(x, y+1, z)])
			&& (z == 0 ? true : visited[world.at(x, y, z-1)])
			&& (z == size-1 ? true : visited[world.at(x, y, z+1)]);
	}
	// joku randomilla tämän vierestä
	// tylsä bruteforcemenetelmä hajotusfiiliksen tuotoksena
	int[] getadj(PApplet pa, int x, int y, int z, boolean[] visited) {
		// {-x, x, -y, y, -z, z}
		int[][] dirs = {
			{-1, 0, 0},
			{1, 0, 0},
			{0, -1, 0},
			{0, 1, 0},
			{0, 0, -1},
			{0, 0, 1}};
		boolean ok = true;
		int[] dir;
		do {
			int i = (int)(pa.random(0, 6));
			dir = dirs[i];
			
			ok = true;
			if (x == 0 && i == 0) ok = false;
			if (y == 0 && i == 2) ok = false;
			if (z == 0 && i == 4) ok = false;
			if (x == size-1 && i == 1) ok = false;
			if (y == size-1 && i == 3) ok = false;
			if (z == size-1 && i == 5) ok = false;
		} while (!ok || visited[world.at(x + dir[0], y + dir[1], z + dir[2])]);
		return dir;
	}
}
