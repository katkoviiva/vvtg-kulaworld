import processing.core.*;
import java.util.*;

// maailma on tilepohjainen ja koostuu kokonaislukukoordinaateissa olevista palikoista
// tarkemmin, se generoidaan n*n verkkoon siten että joka pisteestä pääsee jonnekin
// (minimum spanning tree), verkon eri pisteet space-muuttujan etäisyydellä toisistaan ja välissä tilejä
public class World {
	int size, size3;
	int[] map; // tää olis ehkä kannattanut indeksoida x-, y- ja z-koordinaateilla eikä näin
	static int space = 6;
	PImage boxtex;
	World(PApplet pa, int sz, PImage tex) {
		size = sz;
		size3 = sz * sz * sz;
		map = new int[size3];
		// mapinluontialgo eroteltu jotta koodi ois pikkasen siistimpää
		new PrimMap(this, pa);
		boxtex = tex;
	}
	// onko kalikkaa tässä kohdassa? peliobjektit tarkistavat putoamisen näin
	boolean hasBlk(PVector point) {
		int x = PApplet.round(point.x); // round
		int y = PApplet.round(point.y);
		int z = PApplet.round(point.z);
		return x >= 0 && y >= 0 && z >= 0 
			&& x < size && y < size && z < size 
			&& map[at(x, y, z)] != 0;
	}
	// taulukkoindeksi koordinaateista
	int at(int x, int y, int z) {
		return at(x, y, z, size);
	}
	int at(int x, int y, int z, int size) {
		return size * (size * z + y) + x;
	}
	int at(PVector p) {
		return at(PApplet.round(p.x), PApplet.round(p.y), PApplet.round(p.z));
	}
	// mualimo kuutio kerrallaan
	void draw(PGraphics pa) {
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
	void dobox(PGraphics pa, PVector p, int color) {
		dobox(pa, PApplet.round(p.x), PApplet.round(p.y), PApplet.round(p.z), color);
	}
	void dobox(PGraphics pa, int x, int y, int z) {
		dobox(pa, x, y, z, 0);
	}
	TexCube tcube = new TexCube();
	// piirrä kuutio jos sen väri on jotain muuta kun 0.
	void dobox(PGraphics pa, int x, int y, int z, int color) {
		int colo = color != 0 ? color : (map[size * size * z + size * y + x] == 0 ? 0 : 0xffffffff);
		if (colo == 0) return;
// 		colo = (colo & 0xffffff) | 0x7f000000;
		pa.pushMatrix();
		pa.translate(x, y, z);
		pa.fill(colo);
		pa.texture(boxtex);
		//TexCube t = new TexCube();
		tcube.draw(pa, color == 0 ? boxtex : null, 0.5f);
		pa.popMatrix();
	}
	
	// tätä käytin debuggailutilassa; pelaaja värjäsi tilet joissa oli käynyt jo eri värille
	void visit(PVector point) {
		int x = PApplet.round(point.x);
		int y = PApplet.round(point.y);
		int z = PApplet.round(point.z);
		map[at(x, y, z)] = 0xffffffff;
	}
	
	// maailmassa on välttämättä myös pisteitä joissa ei ole haaroja, laitetaan niiden päihin kolikkoja
	// akseli ulospäin siitä suorasta osasta
	// paluuarvot paikka1, akseli1, ...
	ArrayList<PVector> endpoints() {
		ArrayList<PVector> pts = new ArrayList<PVector>();
		for (int z = 0; z < size; z += space+1) {
			for (int y = 0; y < size; y += space+1) {
				for (int x = 0; x < size; x += space+1) {
					PVector pos = head(x, y, z);
					if (pos != null) {
						pts.add(pos);
						pts.add(PVector.sub(pos, new PVector(x, y, z)));
					}
				}
			}
		}
		return pts;
	}
	
	// tällä funktiolla on huono nimi ja toteutuskin o ruma.
	// tämä on se juttu mikä tekee työt endpoints()ille.
	// jos tilepisteen reunalla toinen tile vain yhdessä suunnassa,
	// niin piste on yksinään. tähän tarttis jonkun kuvan selostamaan.
	PVector head(int x, int y, int z) {
		PVector pp = new PVector(x, y, z);
		PVector[] dirs = {
			new PVector(-1, 0, 0),
			new PVector(1, 0, 0),
			new PVector(0, -1, 0),
			new PVector(0, 1, 0),
			new PVector(0, 0, -1),
			new PVector(0, 0, 1),
		};
		int blkfound = -1;
		for (int i = 0; i < dirs.length; i++) {
			PVector p = dirs[i];
			PVector next = PVector.add(pp, p);
			if (next.x >= 0 && next.x < size
			 && next.y >= 0 && next.y < size
			 && next.z >= 0 && next.z < size) {
				if (map[at(next)] != 0) {
					if (blkfound != -1) return null;
					blkfound = i;
				}
			}
		}
		if (blkfound != -1) return PVector.sub(pp, dirs[blkfound]);
		return null;
	}
}

// prim's algorithm / pienin virittäjäpuu http://en.wikipedia.org/wiki/Prim's_algorithm
// harvassa pisteitä, joista jokaisesta pääsee jotenkin jonnekin
// jokseenkin mielekäs kartta ilman että tarvitsee käsin piirtää, 
// ja tulee vielä erilaisia eri randomseedeillä niin ei ole tylsää

// kartan vokseleita käpistellään taulukkoindeksillä eikä (x,y,z)-kolmikolla
// ehkä vähän hankalaa näin päin kumminkin
class PrimMap {
	World world;
	int size, size3;
	int[] map; // kartassa on värit, 0 jos ei palikkaa
	// ei kyllä oo mitenkään eleganttia että konstruktori tekee kaikki työt
	PrimMap(World world, PApplet pa) {
		size = world.size;
		size3 = world.size3;
		this.world = world;
		generate(pa);
	}
	void generate(PApplet pa) {
		int space = World.space;
		// sz^3 pisteitä, joiden välillä space tyhjää (tyhjä 0: kuutio)
		// eli (sz + (sz - 1) * space) ^ 3 tileä
		// visited ~ V_new wikipedian algossa
		
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
